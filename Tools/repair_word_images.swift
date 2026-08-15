import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let alphaNoiseFloor = 8
private let transparentThreshold = 18
private let opaqueThreshold = 190

private struct ProcessorError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}

private struct ComponentSummary {
    let indices: [Int]
    let bounds: CGRect
    let touchesBorder: Bool
    let area: Int
}

private typealias RGBColor = (red: Int, green: Int, blue: Int)

private struct RepairOptions {
    var removeKeyColor: RGBColor?
    var removeNeonGreen = false
    var despillGreenEdges = false
    var removeLooseComponents = false
    var keepLargestComponentOnly = false
    var trim = 8
    var pad = 24
}

private func smoothstep(_ value: Double) -> Double {
    let clamped = min(max(value, 0), 1)
    return clamped * clamped * (3 - (2 * clamped))
}

private func parseKeyColor(_ value: String) throws -> RGBColor {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "#", with: "")

    guard normalized.count == 6,
          let rawValue = Int(normalized, radix: 16)
    else {
        throw ProcessorError(message: "Invalid key color \(value). Use hex like #00ff00 or #ff00ff.")
    }

    return (
        red: (rawValue >> 16) & 0xFF,
        green: (rawValue >> 8) & 0xFF,
        blue: rawValue & 0xFF
    )
}

private func keyChannels(for keyColor: RGBColor) -> [Int] {
    let channels = [keyColor.red, keyColor.green, keyColor.blue]
    let maximum = channels.max() ?? 0

    return channels.enumerated().compactMap { index, value in
        value >= max(180, maximum - 20) ? index : nil
    }
}

private func loadImage(from url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw ProcessorError(message: "Could not load image at \(url.path).")
    }

    return image
}

private func saveImage(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw ProcessorError(message: "Could not create PNG destination for \(url.path).")
    }

    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        throw ProcessorError(message: "Could not save PNG to \(url.path).")
    }
}

private func makeBitmapContext(width: Int, height: Int) throws -> CGContext {
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw ProcessorError(message: "Could not create bitmap context.")
    }

    return context
}

private func alphaBounds(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>
) -> CGRect? {
    let bytesPerPixel = 4
    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    for y in 0 ..< height {
        for x in 0 ..< width {
            let offset = ((y * width) + x) * bytesPerPixel
            let alpha = Int(pixels[offset + 3])
            guard alpha > alphaNoiseFloor else {
                continue
            }

            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }

    guard maxX >= minX, maxY >= minY else {
        return nil
    }

    return CGRect(
        x: minX,
        y: minY,
        width: (maxX - minX) + 1,
        height: (maxY - minY) + 1
    )
}

private func retainMeaningfulOpaqueComponents(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>,
    keepLargestOnly: Bool
) -> CGRect? {
    let bytesPerPixel = 4
    let pixelCount = width * height
    var visited = Array(repeating: false, count: pixelCount)
    var components: [ComponentSummary] = []

    func alpha(at index: Int) -> Int {
        Int(pixels[(index * bytesPerPixel) + 3])
    }

    let offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    for startIndex in 0 ..< pixelCount {
        guard !visited[startIndex], alpha(at: startIndex) > alphaNoiseFloor else {
            continue
        }

        var queue = [startIndex]
        var cursor = 0
        visited[startIndex] = true
        var component: [Int] = []
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        var touchesBorder = false

        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            component.append(index)

            let x = index % width
            let y = index / width

            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)

            if x == 0 || x == width - 1 || y == 0 || y == height - 1 {
                touchesBorder = true
            }

            for (dx, dy) in offsets {
                let nextX = x + dx
                let nextY = y + dy

                guard nextX >= 0, nextX < width, nextY >= 0, nextY < height else {
                    continue
                }

                let nextIndex = (nextY * width) + nextX
                guard !visited[nextIndex], alpha(at: nextIndex) > alphaNoiseFloor else {
                    continue
                }

                visited[nextIndex] = true
                queue.append(nextIndex)
            }
        }

        components.append(
            ComponentSummary(
                indices: component,
                bounds: CGRect(
                    x: minX,
                    y: minY,
                    width: (maxX - minX) + 1,
                    height: (maxY - minY) + 1
                ),
                touchesBorder: touchesBorder,
                area: component.count
            )
        )
    }

    guard !components.isEmpty,
          let anchor = components.max(by: { $0.area < $1.area })
    else {
        return nil
    }

    if keepLargestOnly {
        var keep = Array(repeating: false, count: pixelCount)
        for index in anchor.indices {
            keep[index] = true
        }

        for index in 0 ..< pixelCount where !keep[index] {
            let offset = index * bytesPerPixel
            pixels[offset] = 0
            pixels[offset + 1] = 0
            pixels[offset + 2] = 0
            pixels[offset + 3] = 0
        }

        return anchor.bounds
    }

    let largeAreaThreshold = max(800, Int(Double(anchor.area) * 0.08))
    let nearbyAreaThreshold = max(40, Int(Double(anchor.area) * 0.006))
    let expandedAnchor = anchor.bounds.insetBy(dx: -90, dy: -90)

    let keptComponents = components.filter { component in
        if component.area == anchor.area && component.bounds == anchor.bounds {
            return true
        }

        if component.area >= largeAreaThreshold {
            return true
        }

        if component.area >= nearbyAreaThreshold, expandedAnchor.intersects(component.bounds) {
            return true
        }

        return false
    }

    var keep = Array(repeating: false, count: pixelCount)
    for component in keptComponents {
        for index in component.indices {
            keep[index] = true
        }
    }

    for index in 0 ..< pixelCount where !keep[index] {
        let offset = index * bytesPerPixel
        pixels[offset] = 0
        pixels[offset + 1] = 0
        pixels[offset + 2] = 0
        pixels[offset + 3] = 0
    }

    var unionBounds = keptComponents[0].bounds
    for component in keptComponents.dropFirst() {
        unionBounds = unionBounds.union(component.bounds)
    }

    return unionBounds
}

private func hasTransparentNeighbor(
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>
) -> Bool {
    let bytesPerPixel = 4

    for deltaY in -1...1 {
        for deltaX in -1...1 {
            guard !(deltaX == 0 && deltaY == 0) else {
                continue
            }

            let nextX = x + deltaX
            let nextY = y + deltaY
            guard nextX >= 0, nextX < width, nextY >= 0, nextY < height else {
                return true
            }

            let offset = ((nextY * width) + nextX) * bytesPerPixel
            let alpha = Int(pixels[offset + 3])
            if alpha <= alphaNoiseFloor {
                return true
            }
        }
    }

    return false
}

private func removeNeonGreenArtifacts(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>
) {
    let bytesPerPixel = 4

    for y in 0 ..< height {
        for x in 0 ..< width {
            let offset = ((y * width) + x) * bytesPerPixel
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let alpha = Int(pixels[offset + 3])

            guard alpha > alphaNoiseFloor else {
                continue
            }

            let maxNonGreen = max(red, blue)
            let greenDominance = green - maxNonGreen
            let isNeonGreen = green >= 170 && greenDominance >= 85 && red <= 150 && blue <= 150

            if isNeonGreen {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
            }
        }
    }
}

private func removeKeyColorArtifacts(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>,
    keyColor: RGBColor
) {
    let bytesPerPixel = 4
    let keyChannelsIndices = keyChannels(for: keyColor)
    let nonKeyChannels = [0, 1, 2].filter { !keyChannelsIndices.contains($0) }

    for y in 0 ..< height {
        for x in 0 ..< width {
            let offset = ((y * width) + x) * bytesPerPixel
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let alpha = Int(pixels[offset + 3])

            let distance = max(
                abs(red - keyColor.red),
                abs(green - keyColor.green),
                abs(blue - keyColor.blue)
            )
            let values = [red, green, blue]
            let keyStrength = keyChannelsIndices.map { values[$0] }.min() ?? 0
            let nonKeyStrength = nonKeyChannels.map { values[$0] }.max() ?? 0
            let dominance = keyStrength - nonKeyStrength

            var outputAlpha = 255
            if keyChannelsIndices.allSatisfy({ values[$0] > 220 }),
               nonKeyChannels.allSatisfy({ values[$0] < 80 })
            {
                outputAlpha = 0
            } else if dominance > 40, distance < opaqueThreshold {
                if distance <= transparentThreshold {
                    outputAlpha = 0
                } else {
                    let ratio = Double(distance - transparentThreshold) / Double(opaqueThreshold - transparentThreshold)
                    outputAlpha = Int(round(255 * smoothstep(ratio)))
                }
            }

            outputAlpha = Int(round(Double(outputAlpha) * (Double(alpha) / 255)))
            if outputAlpha <= alphaNoiseFloor {
                outputAlpha = 0
            }

            if dominance > 40, outputAlpha < 255 {
                let anchor = nonKeyStrength
                for channel in keyChannelsIndices {
                    pixels[offset + channel] = UInt8(min(anchor, 255))
                }
            }

            if outputAlpha == 0 {
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = 0
            } else {
                pixels[offset + 3] = UInt8(outputAlpha)
            }
        }
    }
}

private func despillGreenEdges(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>
) {
    let bytesPerPixel = 4

    for y in 0 ..< height {
        for x in 0 ..< width {
            let offset = ((y * width) + x) * bytesPerPixel
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let alpha = Int(pixels[offset + 3])

            guard alpha > alphaNoiseFloor else {
                continue
            }

            let maxNonGreen = max(red, blue)
            let greenDominance = green - maxNonGreen

            guard greenDominance >= 35,
                  hasTransparentNeighbor(x: x, y: y, width: width, height: height, pixels: pixels)
            else {
                continue
            }

            let replacement = UInt8(min(255, maxNonGreen + 6))
            pixels[offset + 1] = replacement
        }
    }
}

private func makePaddedImage(
    from image: CGImage,
    bounds: CGRect,
    trim: Int,
    pad: Int
) throws -> CGImage {
    let cropX = max(0, Int(bounds.minX) - trim)
    let cropY = max(0, Int(bounds.minY) - trim)
    let cropWidth = min(image.width - cropX, Int(bounds.width) + (trim * 2))
    let cropHeight = min(image.height - cropY, Int(bounds.height) + (trim * 2))
    let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

    guard let trimmed = image.cropping(to: cropRect) else {
        throw ProcessorError(message: "Could not crop repaired image.")
    }

    let outputWidth = trimmed.width + (pad * 2)
    let outputHeight = trimmed.height + (pad * 2)
    let context = try makeBitmapContext(width: outputWidth, height: outputHeight)
    context.clear(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
    context.draw(trimmed, in: CGRect(x: pad, y: pad, width: trimmed.width, height: trimmed.height))

    guard let result = context.makeImage() else {
        throw ProcessorError(message: "Could not create padded image.")
    }

    return result
}

private func repairImage(_ image: CGImage, options: RepairOptions) throws -> CGImage {
    let context = try makeBitmapContext(width: image.width, height: image.height)
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    guard let rawData = context.data else {
        throw ProcessorError(message: "Could not access bitmap data.")
    }

    let bytesPerPixel = 4
    let pixels = rawData.bindMemory(to: UInt8.self, capacity: image.width * image.height * bytesPerPixel)

    if let keyColor = options.removeKeyColor {
        removeKeyColorArtifacts(width: image.width, height: image.height, pixels: pixels, keyColor: keyColor)
    }

    if options.removeNeonGreen {
        removeNeonGreenArtifacts(width: image.width, height: image.height, pixels: pixels)
    }

    if options.despillGreenEdges {
        despillGreenEdges(width: image.width, height: image.height, pixels: pixels)
    }

    let bounds: CGRect?
    if options.removeLooseComponents {
        bounds = retainMeaningfulOpaqueComponents(
            width: image.width,
            height: image.height,
            pixels: pixels,
            keepLargestOnly: options.keepLargestComponentOnly
        )
    } else {
        bounds = alphaBounds(width: image.width, height: image.height, pixels: pixels)
    }

    guard let contentBounds = bounds else {
        throw ProcessorError(message: "Repaired image is empty.")
    }

    guard let processedImage = context.makeImage() else {
        throw ProcessorError(message: "Could not create processed image.")
    }

    return try makePaddedImage(
        from: processedImage,
        bounds: contentBounds,
        trim: options.trim,
        pad: options.pad
    )
}

private func parseArguments() throws -> (RepairOptions, [String]) {
    var options = RepairOptions()
    var files: [String] = []
    var iterator = CommandLine.arguments.dropFirst().makeIterator()

    while let argument = iterator.next() {
        switch argument {
        case "--remove-key-color":
            guard let value = iterator.next() else {
                throw ProcessorError(message: "Missing value after --remove-key-color.")
            }
            options.removeKeyColor = try parseKeyColor(value)
        case "--remove-neon-green":
            options.removeNeonGreen = true
        case "--despill-green":
            options.despillGreenEdges = true
        case "--remove-loose-components":
            options.removeLooseComponents = true
        case "--keep-largest-component-only":
            options.removeLooseComponents = true
            options.keepLargestComponentOnly = true
        case "--trim":
            guard let value = iterator.next(), let trim = Int(value) else {
                throw ProcessorError(message: "Missing integer after --trim.")
            }
            options.trim = max(0, trim)
        case "--pad":
            guard let value = iterator.next(), let pad = Int(value) else {
                throw ProcessorError(message: "Missing integer after --pad.")
            }
            options.pad = max(0, pad)
        default:
            files.append(argument)
        }
    }

    guard !files.isEmpty else {
        throw ProcessorError(
            message: """
            Usage:
              swift Tools/repair_word_images.swift [--remove-key-color #ff00ff] [--remove-neon-green] [--despill-green] [--remove-loose-components] [--keep-largest-component-only] [--trim 8] [--pad 24] <image1.png> <image2.png> ...
            """
        )
    }

    return (options, files)
}

private func main() throws {
    let (options, files) = try parseArguments()

    for path in files {
        let url = URL(fileURLWithPath: path)
        let image = try loadImage(from: url)
        let repaired = try repairImage(image, options: options)
        try saveImage(repaired, to: url)
        print("Repaired \(url.lastPathComponent)")
    }
}

do {
    try main()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
