import Foundation

/// Text operations belong to one namespace/key alternative, not its fallback literal.
enum BNFTextOperation: Equatable {
    case sliceCharacters(Int)
    case invalid

    init(_ expression: String) {
        let prefix = "sliceText[Chars,"
        guard expression.hasPrefix(prefix), expression.hasSuffix("]") else {
            self = .invalid
            return
        }
        let argument = expression.dropFirst(prefix.count).dropLast()
        guard !argument.isEmpty,
              argument.allSatisfy({ $0.isASCII && $0.isNumber }),
              let count = Int(argument) else {
            self = .invalid
            return
        }
        self = .sliceCharacters(count)
    }

    func apply(to value: String) throws -> String {
        switch self {
        case .sliceCharacters(let count):
            // Match PlaceholderPredicateResolver's String.count, including joined emoji.
            return String(value.prefix(count))
        case .invalid:
            throw BNFPlaceholderError.invalidTextOperation
        }
    }
}

extension BNFKeyAndNamespace {
    func applyingTextOperations(to value: String) throws -> String {
        try textOperations.reduce(value) { try $1.apply(to: $0) }
    }
}
