import Foundation

enum WordMatchLibrary {
    static let primerSet: [WordMatchPair] = [
        WordMatchPair(key: "beads", word: "БУСЫ", illustration: .asset(name: "WordBeads")),
        WordMatchPair(key: "bucket", word: "ВЕДРО", illustration: .asset(name: "WordBucket")),
        WordMatchPair(key: "bread", word: "БУЛКА", illustration: .asset(name: "WordBread")),
        WordMatchPair(key: "bag", word: "СУМКА", illustration: .asset(name: "WordBag")),
        WordMatchPair(key: "doll", word: "КУКЛА", illustration: .asset(name: "WordDoll"))
    ]

    static let extendedSet: [WordMatchPair] = [
        WordMatchPair(key: "cat", word: "КОТ", illustration: .bundlePNG(name: "cat")),
        WordMatchPair(key: "dog", word: "ПЁС", illustration: .bundlePNG(name: "dog")),
        WordMatchPair(key: "hedgehog", word: "ЁЖ", illustration: .bundlePNG(name: "hedgehog")),
        WordMatchPair(key: "beetle", word: "ЖУК", illustration: .bundlePNG(name: "beetle")),
        WordMatchPair(key: "crayfish", word: "РАК", illustration: .bundlePNG(name: "crayfish")),
        WordMatchPair(key: "owl", word: "СОВА", illustration: .bundlePNG(name: "owl")),
        WordMatchPair(key: "fox", word: "ЛИСА", illustration: .bundlePNG(name: "fox")),
        WordMatchPair(key: "hare", word: "ЗАЯЦ", illustration: .bundlePNG(name: "hare")),
        WordMatchPair(key: "goat", word: "КОЗА", illustration: .bundlePNG(name: "goat")),
        WordMatchPair(key: "elephant", word: "СЛОН", illustration: .bundlePNG(name: "elephant")),

        WordMatchPair(key: "apple", word: "ЯБЛОКО", illustration: .bundlePNG(name: "apple")),
        WordMatchPair(key: "pear", word: "ГРУША", illustration: .bundlePNG(name: "pear")),
        WordMatchPair(key: "plum", word: "СЛИВА", illustration: .bundlePNG(name: "plum")),
        WordMatchPair(key: "lemon", word: "ЛИМОН", illustration: .bundlePNG(name: "lemon")),
        WordMatchPair(key: "watermelon", word: "АРБУЗ", illustration: .bundlePNG(name: "watermelon")),
        WordMatchPair(key: "melon", word: "ДЫНЯ", illustration: .bundlePNG(name: "melon")),
        WordMatchPair(key: "banana", word: "БАНАН", illustration: .bundlePNG(name: "banana")),
        WordMatchPair(key: "cherry", word: "ВИШНЯ", illustration: .bundlePNG(name: "cherry")),
        WordMatchPair(key: "carrot", word: "МОРКОВЬ", illustration: .bundlePNG(name: "carrot")),
        WordMatchPair(key: "cucumber", word: "ОГУРЕЦ", illustration: .bundlePNG(name: "cucumber")),

        WordMatchPair(key: "car", word: "МАШИНА", illustration: .bundlePNG(name: "car")),
        WordMatchPair(key: "bus", word: "АВТОБУС", illustration: .bundlePNG(name: "bus")),
        WordMatchPair(key: "rocket", word: "РАКЕТА", illustration: .bundlePNG(name: "rocket")),
        WordMatchPair(key: "train", word: "ПОЕЗД", illustration: .bundlePNG(name: "train")),
        WordMatchPair(key: "boat", word: "ЛОДКА", illustration: .bundlePNG(name: "boat")),
        WordMatchPair(key: "airplane", word: "САМОЛЕТ", illustration: .bundlePNG(name: "airplane")),
        WordMatchPair(key: "tractor", word: "ТРАКТОР", illustration: .bundlePNG(name: "tractor")),
        WordMatchPair(key: "ship", word: "КОРАБЛЬ", illustration: .bundlePNG(name: "ship")),
        WordMatchPair(key: "tram", word: "ТРАМВАЙ", illustration: .bundlePNG(name: "tram")),
        WordMatchPair(key: "bicycle", word: "ВЕЛОСИПЕД", illustration: .bundlePNG(name: "bicycle")),

        WordMatchPair(key: "house", word: "ДОМ", illustration: .bundlePNG(name: "house")),
        WordMatchPair(key: "ball", word: "МЯЧ", illustration: .bundlePNG(name: "ball")),
        WordMatchPair(key: "balloon", word: "ШАР", illustration: .bundlePNG(name: "balloon")),
        WordMatchPair(key: "cube", word: "КУБИК", illustration: .bundlePNG(name: "cube")),
        WordMatchPair(key: "spinning-top", word: "ЮЛА", illustration: .bundlePNG(name: "spinning-top")),
        WordMatchPair(key: "teddy-bear", word: "МИШКА", illustration: .bundlePNG(name: "teddy-bear")),
        WordMatchPair(key: "robot", word: "РОБОТ", illustration: .bundlePNG(name: "robot")),
        WordMatchPair(key: "sled", word: "САНКИ", illustration: .bundlePNG(name: "sled")),
        WordMatchPair(key: "scooter", word: "САМОКАТ", illustration: .bundlePNG(name: "scooter")),
        WordMatchPair(key: "stacking-rings", word: "ПИРАМИДКА", illustration: .bundlePNG(name: "stacking-rings")),

        WordMatchPair(key: "cup", word: "ЧАШКА", illustration: .bundlePNG(name: "cup")),
        WordMatchPair(key: "spoon", word: "ЛОЖКА", illustration: .bundlePNG(name: "spoon")),
        WordMatchPair(key: "fork", word: "ВИЛКА", illustration: .bundlePNG(name: "fork")),
        WordMatchPair(key: "plate", word: "ТАРЕЛКА", illustration: .bundlePNG(name: "plate")),
        WordMatchPair(key: "teapot", word: "ЧАЙНИК", illustration: .bundlePNG(name: "teapot")),
        WordMatchPair(key: "scissors", word: "НОЖНИЦЫ", illustration: .bundlePNG(name: "scissors")),
        WordMatchPair(key: "hammer", word: "МОЛОТОК", illustration: .bundlePNG(name: "hammer")),
        WordMatchPair(key: "watering-can", word: "ЛЕЙКА", illustration: .bundlePNG(name: "watering-can")),
        WordMatchPair(key: "umbrella", word: "ЗОНТ", illustration: .bundlePNG(name: "umbrella")),
        WordMatchPair(key: "clock", word: "ЧАСЫ", illustration: .bundlePNG(name: "clock")),

        WordMatchPair(key: "book", word: "КНИГА", illustration: .bundlePNG(name: "book")),
        WordMatchPair(key: "paint-set", word: "КРАСКИ", illustration: .bundlePNG(name: "paint-set")),
        WordMatchPair(key: "paintbrush", word: "КИСТЬ", illustration: .bundlePNG(name: "paintbrush")),
        WordMatchPair(key: "pen", word: "РУЧКА", illustration: .bundlePNG(name: "pen")),
        WordMatchPair(key: "pencil", word: "КАРАНДАШ", illustration: .bundlePNG(name: "pencil")),
        WordMatchPair(key: "notebook", word: "ТЕТРАДЬ", illustration: .bundlePNG(name: "notebook")),
        WordMatchPair(key: "palette", word: "ПАЛИТРА", illustration: .bundlePNG(name: "palette")),
        WordMatchPair(key: "backpack", word: "РЮКЗАК", illustration: .bundlePNG(name: "backpack")),
        WordMatchPair(key: "ruler", word: "ЛИНЕЙКА", illustration: .bundlePNG(name: "ruler")),
        WordMatchPair(key: "globe", word: "ГЛОБУС", illustration: .bundlePNG(name: "globe")),

        WordMatchPair(key: "hat", word: "ШАПКА", illustration: .bundlePNG(name: "hat")),
        WordMatchPair(key: "scarf", word: "ШАРФ", illustration: .bundlePNG(name: "scarf")),
        WordMatchPair(key: "socks", word: "НОСКИ", illustration: .bundlePNG(name: "socks")),
        WordMatchPair(key: "boots", word: "БОТИНКИ", illustration: .bundlePNG(name: "boots")),
        WordMatchPair(key: "dress", word: "ПЛАТЬЕ", illustration: .bundlePNG(name: "dress")),
        WordMatchPair(key: "skirt", word: "ЮБКА", illustration: .bundlePNG(name: "skirt")),
        WordMatchPair(key: "sweater", word: "КОФТА", illustration: .bundlePNG(name: "sweater")),
        WordMatchPair(key: "mittens", word: "ВАРЕЖКИ", illustration: .bundlePNG(name: "mittens")),
        WordMatchPair(key: "shorts", word: "ШОРТЫ", illustration: .bundlePNG(name: "shorts")),
        WordMatchPair(key: "rain-boots", word: "САПОГИ", illustration: .bundlePNG(name: "rain-boots")),

        WordMatchPair(key: "flower", word: "ЦВЕТОК", illustration: .bundlePNG(name: "flower")),
        WordMatchPair(key: "tree", word: "ДЕРЕВО", illustration: .bundlePNG(name: "tree")),
        WordMatchPair(key: "mushroom", word: "ГРИБ", illustration: .bundlePNG(name: "mushroom")),
        WordMatchPair(key: "leaf", word: "ЛИСТ", illustration: .bundlePNG(name: "leaf")),
        WordMatchPair(key: "cloud", word: "ТУЧА", illustration: .bundlePNG(name: "cloud")),
        WordMatchPair(key: "sun", word: "СОЛНЦЕ", illustration: .bundlePNG(name: "sun")),
        WordMatchPair(key: "moon", word: "ЛУНА", illustration: .bundlePNG(name: "moon")),
        WordMatchPair(key: "star", word: "ЗВЕЗДА", illustration: .bundlePNG(name: "star")),
        WordMatchPair(key: "rainbow", word: "РАДУГА", illustration: .bundlePNG(name: "rainbow")),
        WordMatchPair(key: "snowman", word: "СНЕГОВИК", illustration: .bundlePNG(name: "snowman")),

        WordMatchPair(key: "juice", word: "СОК", illustration: .bundlePNG(name: "juice")),
        WordMatchPair(key: "cake", word: "ТОРТ", illustration: .bundlePNG(name: "cake")),
        WordMatchPair(key: "onion", word: "ЛУК", illustration: .bundlePNG(name: "onion")),
        WordMatchPair(key: "cheese", word: "СЫР", illustration: .bundlePNG(name: "cheese")),
        WordMatchPair(key: "soup", word: "СУП", illustration: .bundlePNG(name: "soup")),
        WordMatchPair(key: "porridge", word: "КАША", illustration: .bundlePNG(name: "porridge")),
        WordMatchPair(key: "milk", word: "МОЛОКО", illustration: .bundlePNG(name: "milk")),
        WordMatchPair(key: "candy", word: "КОНФЕТА", illustration: .bundlePNG(name: "candy")),
        WordMatchPair(key: "ice-cream", word: "МОРОЖЕНОЕ", illustration: .bundlePNG(name: "ice-cream")),
        WordMatchPair(key: "cookie", word: "ПЕЧЕНЬЕ", illustration: .bundlePNG(name: "cookie")),

        WordMatchPair(key: "drum", word: "БАРАБАН", illustration: .bundlePNG(name: "drum")),
        WordMatchPair(key: "flute", word: "ДУДКА", illustration: .bundlePNG(name: "flute")),
        WordMatchPair(key: "flag", word: "ФЛАГ", illustration: .bundlePNG(name: "flag")),
        WordMatchPair(key: "key", word: "КЛЮЧ", illustration: .bundlePNG(name: "key")),
        WordMatchPair(key: "padlock", word: "ЗАМОК", illustration: .bundlePNG(name: "padlock")),
        WordMatchPair(key: "candle", word: "СВЕЧА", illustration: .bundlePNG(name: "candle")),
        WordMatchPair(key: "bed", word: "КРОВАТЬ", illustration: .bundlePNG(name: "bed")),
        WordMatchPair(key: "pillow", word: "ПОДУШКА", illustration: .bundlePNG(name: "pillow")),
        WordMatchPair(key: "soap", word: "МЫЛО", illustration: .bundlePNG(name: "soap")),
        WordMatchPair(key: "brush", word: "ЩЕТКА", illustration: .bundlePNG(name: "brush"))
    ]

    static let all = primerSet + extendedSet

    static func defaultPool() -> [WordMatchPair] {
        ProcessInfo.processInfo.arguments.contains("UITestSmallWordSet") ? primerSet : all
    }
}
