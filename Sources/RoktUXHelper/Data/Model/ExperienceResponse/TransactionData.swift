import Foundation

struct TransactionData: Codable {
    let shippingAddress: Address?
    let billingAddress: Address?
    let paymentType: String?
    let supportedPaymentMethods: [PaymentMethod]?
    let isPartnerManagedPurchase: Bool
    let partnerPaymentReference: String?
    let confirmationRef: String?
    let metadata: [String: String]
}

struct PaymentMethod: Codable {
    enum MethodType: String, Codable {
        case unspecified = "UNSPECIFIED"
        case other = "OTHER"
        case card = "CARD"
        case applePay = "APPLE_PAY"
        case paypal = "PAYPAL"
        case googlePay = "GOOGLE_PAY"
        case afterpay = "AFTERPAY"
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = MethodType(rawValue: raw) ?? .unknown
        }
    }

    let type: MethodType
}

struct Address: Codable {
    let name: String
    let address1: String
    let address2: String?
    let city: String
    let state: String
    let stateCode: String
    let country: String
    let countryCode: String
    let zip: String?
}
