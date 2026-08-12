import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let expectedColumns = 5
private let expectedRows = 2
private let horizontalInset = 4
private let verticalInset = 4
private let trimPadding = 8
private let alphaNoiseFloor = 8
private let transparentThreshold = 18
private let opaqueThreshold = 190

private typealias RGBColor = (red: Int, green: Int, blue: Int)

private struct ProcessorError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
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

private func cropRect(
    width: Int,
    height: Int,
    column: Int,
    row: Int
) -> CGRect {
    let x0 = Int(floor(Double(column) * Double(width) / Double(expectedColumns)))
    let x1 = Int(floor(Double(column + 1) * Double(width) / Double(expectedColumns)))

    let y0 = Int(floor(Double(row) * Double(height) / Double(expectedRows)))
    let y1 = Int(floor(Double(row + 1) * Double(height) / Double(expectedRows)))

    return CGRect(
        x: x0 + horizontalInset,
        y: y0 + verticalInset,
        width: max(1, x1 - x0 - (horizontalInset * 2)),
        height: max(1, y1 - y0 - (verticalInset * 2))
    )
}

private struct ComponentSummary {
    let indices: [Int]
    let bounds: CGRect
    let touchesBorder: Bool
    let area: Int
}

private func retainMeaningfulOpaqueComponents(
    width: Int,
    height: Int,
    pixels: UnsafeMutablePointer<UInt8>
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
        guard !visited[startIndex], alpha(at: startIndex) > 0 else {
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
                guard !visited[nextIndex], alpha(at: nextIndex) > 0 else {
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
                touchesBorder: touchesBorder
                ,
                area: component.count
            )
        )
    }

    guard !components.isEmpty else {
        return nil
    }

    guard let anchor = components.max(by: { $0.area < $1.area }) else {
        return nil
    }

    let largeAreaThreshold = max(1200, Int(Double(anchor.area) * 0.08))
    let nearbyAreaThreshold = max(120, Int(Double(anchor.area) * 0.01))
    let expandedAnchor = anchor.bounds.insetBy(dx: -80, dy: -80)

    let keptComponents = components.filter { component in
        if component.area == anchor.area && component.bounds == anchor.bounds {
            return true
        }

        if component.area >= largeAreaThreshold {
            return true
        }

        if !component.touchesBorder,
           component.area >= nearbyAreaThreshold,
           expandedAnchor.intersects(component.bounds)
        {
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

private func processImage(_ image: CGImage, keyColor: RGBColor) throws -> CGImage {
    let width = image.width
    let height = image.height
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

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let rawData = context.data else {
        throw ProcessorError(message: "Could not access bitmap data.")
    }

    let pixelCount = width * height
    let pixels = rawData.bindMemory(to: UInt8.self, capacity: pixelCount * bytesPerPixel)
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
               nonKeyChannels.allSatisfy({ values[$0] < 60 })
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

    guard let componentBounds = retainMeaningfulOpaqueComponents(width: width, height: height, pixels: pixels) else {
        throw ProcessorError(message: "Processed image is empty.")
    }

    guard let processedImage = context.makeImage() else {
        throw ProcessorError(message: "Could not create processed image.")
    }

    let cropX = max(0, Int(componentBounds.minX) - trimPadding)
    let cropY = max(0, Int(componentBounds.minY) - trimPadding)
    let cropWidth = min(width - cropX, Int(componentBounds.width) + (trimPadding * 2))
    let cropHeight = min(height - cropY, Int(componentBounds.height) + (trimPadding * 2))
    let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

    guard let trimmedImage = processedImage.cropping(to: cropRect) else {
        throw ProcessorError(message: "Could not trim processed image.")
    }

    return trimmedImage
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

private func loadImage(from url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw ProcessorError(message: "Could not load image at \(url.path).")
    }

    return image
}

private func main() throws {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var keyColor: RGBColor = (red: 0, green: 255, blue: 0)

    if arguments.first == "--key" {
        guard arguments.count >= 2 else {
            throw ProcessorError(message: "Missing value after --key.")
        }

        keyColor = try parseKeyColor(arguments[1])
        arguments.removeFirst(2)
    }

    let requiredCount = 2 + (expectedColumns * expectedRows)
    guard arguments.count == requiredCount else {
        throw ProcessorError(
            message: """
            Usage:
              swift Tools/process_word_sheet.swift [--key #00ff00] <input.png> <output-dir> <name1> ... <name10>
            """
        )
    }

    let inputURL = URL(fileURLWithPath: arguments[0])
    let outputDirectoryURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
    let names = Array(arguments.dropFirst(2))

    let sheetImage = try loadImage(from: inputURL)
    try FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true)

    for index in names.indices {
        let column = index % expectedColumns
        let row = index / expectedColumns
        let rect = cropRect(width: sheetImage.width, height: sheetImage.height, column: column, row: row)

        guard let croppedImage = sheetImage.cropping(to: rect.integral) else {
            throw ProcessorError(message: "Could not crop cell \(index) from sheet.")
        }

        let transparentImage = try processImage(croppedImage, keyColor: keyColor)
        let outputURL = outputDirectoryURL.appendingPathComponent("\(names[index]).png")
        try saveImage(transparentImage, to: outputURL)
    }
}

do {
    try main()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
