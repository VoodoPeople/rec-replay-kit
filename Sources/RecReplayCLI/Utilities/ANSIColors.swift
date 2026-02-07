import Foundation

enum ANSIColor: String {
    case reset = "\u{001B}[0m"
    case bold = "\u{001B}[1m"
    case dim = "\u{001B}[2m"

    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
    case gray = "\u{001B}[90m"

    case bgRed = "\u{001B}[41m"
    case bgGreen = "\u{001B}[42m"
    case bgYellow = "\u{001B}[43m"
}

extension String {
    func colored(_ color: ANSIColor, enabled: Bool = true) -> String {
        guard enabled else { return self }
        return "\(color.rawValue)\(self)\(ANSIColor.reset.rawValue)"
    }

    func bold(enabled: Bool = true) -> String {
        guard enabled else { return self }
        return "\(ANSIColor.bold.rawValue)\(self)\(ANSIColor.reset.rawValue)"
    }

    func dim(enabled: Bool = true) -> String {
        guard enabled else { return self }
        return "\(ANSIColor.dim.rawValue)\(self)\(ANSIColor.reset.rawValue)"
    }
}
