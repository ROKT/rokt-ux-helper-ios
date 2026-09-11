import Foundation
import DcuiSchema

/// Maps the canonical ``SelectResponse`` into the renderer's ``RoktUXPageModel`` /
/// ``LayoutPlugin`` domain models.
///
/// This is the single response-to-page-model mapper used by every raw entry point
/// (`RoktUX.parseExperience` and both `loadLayout(experienceResponse:)` families),
/// replacing the removed camel-case wire tree and its per-integration
/// `getPageModel()` implementations. The offer/creative/catalog/transaction subtree
/// is re-homed to the renderer's existing typed models with no field loss; the
/// pre-parsed DCUI layout schemas are already typed on ``SelectResponse`` and are
/// carried through unchanged.
@available(iOS 13, *)
extension SelectResponse {

    /// Builds the page model, or returns `nil` when the response has no renderable
    /// layout (no first-plugin outer layout schema, or that schema has no layout).
    ///
    /// - Parameter useDiagnosticEvents: whether diagnostic events are enabled for
    ///   this integration. Preserves the historical SDK (on) vs S2S (off) difference —
    ///   the v2 response carries no `options`, so callers pass it explicitly.
    func getPageModel(useDiagnosticEvents: Bool) -> RoktUXPageModel? {
        guard let outerLayoutSchema = plugins?.first?.plugin?.config?.outerLayoutSchema,
              outerLayoutSchema.layout != nil
        else { return nil }

        return RoktUXPageModel(
            pageId: pageContext?.pageId,
            sessionId: sessionId,
            pageInstanceGuid: pageContext?.pageInstanceGuid ?? pageInstanceGuid,
            layoutPlugins: mapLayoutPlugins(),
            token: pageContext?.token ?? sessionToken.token,
            options: useDiagnosticEvents ? [.useDiagnosticEvents] : nil
        )
    }

    private func mapLayoutPlugins() -> [LayoutPlugin] {
        (plugins ?? []).compactMap { selectPlugin -> LayoutPlugin? in
            guard let layout = selectPlugin.plugin else { return nil }
            let config = layout.config
            let outer = config?.outerLayoutSchema
            return LayoutPlugin(
                pluginInstanceGuid: config?.instanceGuid ?? "",
                breakpoints: outer?.breakpoints,
                settings: outer?.settings,
                layout: outer?.layout,
                slots: (config?.slots ?? []).map { $0.toSlotModel() },
                targetElementSelector: layout.targetElementSelector,
                pluginConfigJWTToken: config?.token ?? "",
                pluginId: layout.id ?? "",
                pluginName: layout.name
            )
        }
    }
}

@available(iOS 13, *)
private extension SelectSlot {
    func toSlotModel() -> SlotModel {
        SlotModel(
            instanceGuid: instanceGuid,
            offer: offer?.toOfferModel(),
            layoutVariant: layoutVariant.map {
                LayoutVariantModel(layoutVariantSchema: $0.layoutVariantSchema, moduleName: $0.moduleName)
            },
            jwtToken: token ?? ""
        )
    }
}

private extension SelectOffer {
    /// An offer is only renderable with a creative; without one there is nothing to
    /// map (matches the legacy adapter, which dropped the offer entirely).
    func toOfferModel() -> OfferModel? {
        guard let creative else { return nil }
        return OfferModel(
            campaignId: campaignId,
            creative: creative.toCreativeModel(),
            catalogItems: catalogItems?.map { $0.toCatalogItem() },
            catalogItemGroup: catalogItemGroup?.toCatalogItemGroup(),
            transactionData: transactionData?.toTransactionData(),
            accountId: accountId,
            catalogItemResponseAction: catalogItemResponseAction
        )
    }
}

private extension SelectCreative {
    func toCreativeModel() -> CreativeModel {
        CreativeModel(
            referralCreativeId: referralCreativeId ?? "",
            instanceGuid: instanceGuid ?? "",
            copy: copy ?? [:],
            images: images?.mapValues { $0.toCreativeImage() },
            links: links?.mapValues { $0.toCreativeLink() },
            responseOptionsMap: responseOptionsMap.flatMap(Self.bucketResponseOptions),
            jwtToken: token ?? ""
        )
    }

    /// The renderer keys response options positionally as `positive`/`negative`, not
    /// by the response map key — options are bucketed on `is_positive` (first wins,
    /// ordered by id for determinism). Matches the legacy adapter.
    static func bucketResponseOptions(_ map: [String: SelectResponseOption]) -> ResponseOptionList? {
        var positive: SelectResponseOption?
        var negative: SelectResponseOption?
        for option in map.values.sorted(by: { ($0.id ?? "") < ($1.id ?? "") }) {
            if option.isPositive {
                positive = positive ?? option
            } else {
                negative = negative ?? option
            }
        }
        guard positive != nil || negative != nil else { return nil }
        return ResponseOptionList(
            positive: positive?.toRoktUXResponseOption(),
            negative: negative?.toRoktUXResponseOption()
        )
    }
}

private extension SelectResponseOption {
    func toRoktUXResponseOption() -> RoktUXResponseOption {
        RoktUXResponseOption(
            id: id ?? "",
            action: action.map { Action(rawValue: $0) ?? .unknown },
            instanceGuid: instanceGuid ?? "",
            signalType: signalType.map { RoktUXSignalType(rawValue: $0) ?? .unknown },
            shortLabel: shortLabel,
            longLabel: longLabel,
            shortSuccessLabel: shortSuccessLabel,
            isPositive: isPositive,
            url: url,
            responseJWTToken: token ?? "",
            urlBehavior: urlBehavior,
            ignoreBranch: ignoreBranch
        )
    }
}

private extension SelectImage {
    func toCreativeImage() -> CreativeImage {
        CreativeImage(light: light, dark: dark, alt: alt, title: title)
    }
}

private extension SelectLink {
    func toCreativeLink() -> CreativeLink {
        CreativeLink(url: url, title: title)
    }
}

private extension SelectCatalogItem {
    /// Re-homes a shoppable catalog item to the renderer's ``CatalogItem``. Fields the
    /// renderer requires but the response can omit default to empty;
    /// `positiveResponseText`/`negativeResponseText` are required by the model yet read
    /// nowhere, so they default to empty (matches the legacy adapter).
    func toCatalogItem() -> CatalogItem {
        CatalogItem(
            images: images?.mapValues { $0.toCreativeImage() } ?? [:],
            catalogItemId: catalogItemId ?? "",
            cartItemId: cartItemId ?? "",
            instanceGuid: instanceGuid ?? "",
            title: title ?? "",
            description: description ?? "",
            price: price.flatMap { Decimal(string: String($0)) },
            priceFormatted: priceFormatted,
            originalPrice: originalPrice.flatMap { Decimal(string: String($0)) },
            originalPriceFormatted: originalPriceFormatted,
            currency: currency ?? "",
            signalType: signalType,
            url: url,
            minItemCount: minItemCount,
            maxItemCount: maxItemCount,
            preSelectedQuantity: preSelectedQuantity,
            providerData: providerData ?? "",
            urlBehavior: urlBehavior,
            positiveResponseText: positiveResponseText ?? "",
            negativeResponseText: negativeResponseText ?? "",
            // ponytail: domain `addOns` is [String]; the v2 wire `add_ons` is a complex
            // object array. Not surfaced (matches the shipping SDK adapter); revisit if
            // the renderer starts consuming structured add-ons.
            addOns: nil,
            copy: copy,
            inventoryStatus: inventoryStatus,
            linkedProductId: linkedProductId,
            token: token ?? "",
            responseOptionsMap: responseOptionsMap?.mapValues { $0.toRoktUXResponseOption() },
            productCartAttribute1: productCartAttribute1,
            productCartAttribute2: productCartAttribute2,
            productSku: productSku,
            catalogId: catalogId
        )
    }
}

private extension SelectCatalogItemGroup {
    func toCatalogItemGroup() -> CatalogItemGroup {
        CatalogItemGroup(
            groupId: groupId ?? "",
            catalogItemIds: catalogItemIds ?? [],
            attributes: attributes?.map { $0.toAttribute() },
            metadata: metadata
        )
    }
}

private extension SelectCatalogItemGroupAttribute {
    func toAttribute() -> CatalogItemGroupAttribute {
        CatalogItemGroupAttribute(
            attributeId: attributeId ?? "",
            label: label,
            options: options?.map { $0.toOption() },
            metadata: metadata
        )
    }
}

private extension SelectCatalogItemGroupOption {
    func toOption() -> CatalogItemGroupOption {
        CatalogItemGroupOption(label: label, catalogItemIds: catalogItemIds, metadata: metadata)
    }
}

private extension SelectTransactionData {
    func toTransactionData() -> TransactionData {
        TransactionData(
            shippingAddress: shippingAddress?.toAddress(),
            billingAddress: billingAddress?.toAddress(),
            paymentType: paymentType,
            supportedPaymentMethods: supportedPaymentMethods?.map {
                PaymentMethod(type: PaymentMethod.MethodType(rawValue: $0.type ?? "") ?? .unknown)
            },
            isPartnerManagedPurchase: isPartnerManagedPurchase ?? false,
            partnerPaymentReference: partnerPaymentReference,
            confirmationRef: confirmationRef,
            metadata: metadata ?? [:]
        )
    }
}

private extension SelectAddress {
    func toAddress() -> Address {
        Address(
            name: name ?? "",
            address1: address1 ?? "",
            address2: address2,
            city: city ?? "",
            state: state ?? "",
            stateCode: stateCode ?? "",
            country: country ?? "",
            countryCode: countryCode ?? "",
            zip: zip
        )
    }
}
