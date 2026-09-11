import Foundation
public struct RoktUXResponseOption: Codable, Hashable {
    public let id: String
    public let action: Action?
    public let instanceGuid: String
    public let signalType: RoktUXSignalType?
    public let shortLabel: String?
    public let longLabel: String?
    public let shortSuccessLabel: String?
    public let isPositive: Bool?
    public let url: String?
    public let responseJWTToken: String
    public let urlBehavior: String?
    public let ignoreBranch: Bool?

    init(id: String,
         action: Action?,
         instanceGuid: String,
         signalType: RoktUXSignalType?,
         shortLabel: String?,
         longLabel: String?,
         shortSuccessLabel: String?,
         isPositive: Bool?,
         url: String?,
         responseJWTToken: String,
         urlBehavior: String? = nil,
         ignoreBranch: Bool? = nil) {
        self.id = id
        self.action = action
        self.instanceGuid = instanceGuid
        self.signalType = signalType
        self.shortLabel = shortLabel
        self.longLabel = longLabel
        self.shortSuccessLabel = shortSuccessLabel
        self.isPositive = isPositive
        self.url = url
        self.responseJWTToken = responseJWTToken
        self.urlBehavior = urlBehavior
        self.ignoreBranch = ignoreBranch
    }

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case instanceGuid
        case signalType
        case shortLabel
        case longLabel
        case shortSuccessLabel
        case isPositive
        case url
        case responseJWTToken = "token"
        case urlBehavior
        case ignoreBranch
    }
}

public enum RoktUXSignalType: String, Codable, RoktUXCaseIterableDefaultLast {
    case signalResponse = "SignalResponse"
    case signalGatedResponse = "SignalGatedResponse"
    case signalProductItemResponse = "SignalProductItemResponse"
    case unknown
}

public enum Action: String, Codable, RoktUXCaseIterableDefaultLast {
    case url = "Url"
    case captureOnly = "CaptureOnly"
    case external = "ExternalPaymentTrigger"
    case unknown
}
