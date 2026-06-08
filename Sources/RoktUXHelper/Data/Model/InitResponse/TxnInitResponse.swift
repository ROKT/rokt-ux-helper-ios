import Foundation

public struct TxnInitResponse: Decodable, Equatable {
    public let sessionId: String
    public let sessionToken: TxnSessionToken
    public let featureFlags: TxnFeatureFlags
    public let fonts: [TxnFontItem]

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case sessionToken = "session_token"
        case featureFlags = "feature_flags"
        case fonts
    }

    public init(
        sessionId: String,
        sessionToken: TxnSessionToken,
        featureFlags: TxnFeatureFlags,
        fonts: [TxnFontItem]
    ) {
        self.sessionId = sessionId
        self.sessionToken = sessionToken
        self.featureFlags = featureFlags
        self.fonts = fonts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        sessionToken = try container.decode(TxnSessionToken.self, forKey: .sessionToken)
        // Tolerate absent feature_flags/fonts so a missing block doesn't fail init.
        featureFlags = try container.decodeIfPresent(TxnFeatureFlags.self, forKey: .featureFlags)
            ?? TxnFeatureFlags(flags: [:])
        fonts = try container.decodeIfPresent([TxnFontItem].self, forKey: .fonts) ?? []
    }
}

public struct TxnSessionToken: Decodable, Equatable {
    public let token: String
    public let expiresAt: Int64 // Unix epoch milliseconds

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }

    public init(token: String, expiresAt: Int64) {
        self.token = token
        self.expiresAt = expiresAt
    }

    public var expiresAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(expiresAt)/1000)
    }
}

public struct TxnFontItem: Decodable, Equatable {
    public let fontName: String
    public let fontURL: String
    public let fontStyle: String?
    public let fontWeight: String?
    public let fontPostScriptName: String?

    enum CodingKeys: String, CodingKey {
        case fontName = "font_name"
        case fontURL = "font_url"
        case fontStyle = "font_style"
        case fontWeight = "font_weight"
        case fontPostScriptName = "font_post_script_name"
    }

    public init(
        fontName: String,
        fontURL: String,
        fontStyle: String? = nil,
        fontWeight: String? = nil,
        fontPostScriptName: String? = nil
    ) {
        self.fontName = fontName
        self.fontURL = fontURL
        self.fontStyle = fontStyle
        self.fontWeight = fontWeight
        self.fontPostScriptName = fontPostScriptName
    }
}

public enum TxnFeatureFlagValue: Decodable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Bool before the numeric kinds so JSON booleans aren't coerced into numbers.
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported feature flag value type"
            )
        }
    }
}

public struct TxnFeatureFlags: Decodable, Equatable {
    public let flags: [String: TxnFeatureFlagValue]

    public init(flags: [String: TxnFeatureFlagValue]) {
        self.flags = flags
    }

    public init(from decoder: Decoder) throws {
        // Decode per-key and skip values whose type isn't modeled, so a single
        // unknown/extensible server flag can't fail the whole init response.
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decoded: [String: TxnFeatureFlagValue] = [:]
        for key in container.allKeys {
            if let value = try? container.decode(TxnFeatureFlagValue.self, forKey: key) {
                decoded[key.stringValue] = value
            }
        }
        flags = decoded
    }

    private struct DynamicCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    public func bool(forKey key: String) -> Bool? {
        if case .bool(let value) = flags[key] { return value }
        return nil
    }

    public func int(forKey key: String) -> Int? {
        if case .int(let value) = flags[key] { return value }
        return nil
    }

    public func string(forKey key: String) -> String? {
        if case .string(let value) = flags[key] { return value }
        return nil
    }
}
