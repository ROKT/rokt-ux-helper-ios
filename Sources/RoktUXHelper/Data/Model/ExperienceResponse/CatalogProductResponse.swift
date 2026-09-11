import Foundation

struct CatalogProductResponse {
    let context: CatalogItemContext
    let option: RoktUXResponseOption
    let url: URL

    init?(context: CatalogItemContext, responseKey: String? = nil) {
        guard context.moduleName == "standard-marketing",
              context.offer.catalogItemResponseAction == nil || context.offer.catalogItemResponseAction == "Url",
              let option = context.responseOption(for: responseKey),
              option.action == .url,
              option.signalType == .signalProductItemResponse,
              option.isPositive == true,
              !option.instanceGuid.isEmpty,
              !option.responseJWTToken.isEmpty,
              let urlString = option.url,
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              !["javascript", "data", "file"].contains(scheme),
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !["http", "https"].contains(scheme) || url.host?.isEmpty == false else { return nil }

        self.context = context
        self.option = option
        self.url = url
    }

    var metadata: [String: String] {
        let item = context.catalogItem
        var values = [
            kCatalogItemId: item.catalogItemId,
            "productSku": nonEmpty(item.productSku) ?? item.copy?["provider.productSku"] ?? "",
            "catalogId": nonEmpty(item.catalogId) ?? item.copy?["provider.catalogId"] ?? ""
        ]
        values["accountId"] = context.offer.accountId
        return values
    }

    func openURLType(sessionId: String?) -> RoktUXOpenURLType {
        if option.urlBehavior == "overrideLinkNavigation" { return .passthrough }
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return .externally }
        switch option.urlBehavior {
        case "self", "inApp", "roktWebViewSDK":
            return .internally(sessionId: sessionId)
        default:
            return .externally
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        value.flatMap { $0.isEmpty ? nil : $0 }
    }
}
