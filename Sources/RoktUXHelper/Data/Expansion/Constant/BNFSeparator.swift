import Foundation

enum BNFSeparator: String {
    case startDelimiter = "%^"
    case endDelimiter = "^%"
    case namespace = "."
    case alternative = "|"

    /// Length in the units `NSRegularExpression` matches in, for arithmetic on a match's `NSRange`.
    var utf16Count: Int { self.rawValue.utf16.count }
}
