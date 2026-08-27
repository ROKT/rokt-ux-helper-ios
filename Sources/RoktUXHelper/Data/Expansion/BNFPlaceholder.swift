import Foundation

struct BNFPlaceholder: Equatable {
    // Preserve plain-placeholder matching, while letting validation reject malformed operation arguments.
    static let expression = tokenExpression(characters: "a-zA-Z0-9 .|")
    static let deferredExpression = tokenExpression(characters: "a-zA-Z0-9 .|_$\\-")

    private static func tokenExpression(characters: String) -> String {
        "(?<=\\%\\^)(?:[\(characters)]*|[\(characters)]*:(?:(?!\\%\\^|\\^\\%).)*)(?=\\^\\%)"
    }

    let parseableChains: [BNFKeyAndNamespace]
    let defaultValue: String?

    var hasTextOperations: Bool { parseableChains.contains { !$0.textOperations.isEmpty } }
}

enum BNFPlaceholderError: Error {
    case mandatoryKeyEmpty
    case invalidTextOperation
}

struct BNFKeyAndNamespace: Equatable {
    let key: String
    let namespace: BNFNamespace
    var isMandatory: Bool = false
    var textOperations: [BNFTextOperation] = []
}
