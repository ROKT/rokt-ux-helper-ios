import Foundation
import DcuiSchema

/// One builder per layout node kind, split out of the switch in `transform(_:context:)`.
///
/// Every builder takes the whole `LayoutSchemaModel` and re-matches it rather than receiving an
/// already-bound payload, which is what keeps the recursive frame small: the payload copy — around
/// 400 bytes for the container models, up to about 2.9 KB for the catalog ones — is reserved in the
/// builder's frame, which lives only for that one call, instead of in `transform`'s frame alongside
/// the other 30. Passing the payload instead measured 43 KB in `transform` against 1.2 KB this way.
///
/// The `guard case` in each builder cannot fail: `transform` dispatched on the same node's kind.
/// It throws rather than trapping so that a future mis-route degrades to a layout failure instead
/// of taking down the host application, and `LayoutNodeKindTests` covers the routing.
///
/// `@inline(never)` keeps the optimiser from merging the frames back together in a release build.
@available(iOS 15, *)
extension LayoutTransformer {

    @inline(never)
    func transformRow(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .row(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .row(
            try getRow(
                model.styles,
                children: transformChildren(model.children, context: context),
                catalogItemContext: context.catalogItemContext
            )
        )
    }

    @inline(never)
    func transformColumn(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .column(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .column(
            try getColumn(
                model.styles,
                children: transformChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformZStack(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .zStack(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .zStack(
            try getZStack(
                model.styles,
                children: transformChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformScrollableColumn(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .scrollableColumn(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .scrollableColumn(
            try getScrollableColumn(
                model.styles,
                children: transformChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformScrollableRow(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .scrollableRow(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .scrollableRow(
            try getScrollableRow(
                model.styles,
                children: transformChildren(model.children, context: context),
                catalogItemContext: context.catalogItemContext
            )
        )
    }

    @inline(never)
    func transformBasicText(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .basicText(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .basicText(try getBasicText(model, context: context))
    }

    @inline(never)
    func transformRichText(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .richText(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .richText(try getRichText(model, context: context))
    }

    @inline(never)
    func transformStaticImage(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .staticImage(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .staticImage(try getStaticImage(model))
    }

    @inline(never)
    func transformDataImage(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .dataImage(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try transformWithFallback {
            .dataImage(try getDataImage(model, context: context))
        }
    }

    @inline(never)
    func transformDataImageCarousel(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .dataImageCarousel(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try transformWithFallback {
            .dataImageCarousel(try getDataImageCarousel(model, context: context))
        }
    }

    @inline(never)
    func transformProgressIndicator(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .progressIndicator(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .progressIndicator(try getProgressIndicatorUIModel(model, context: context))
    }

    @inline(never)
    func transformCreativeResponse(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .creativeResponse(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try getCreativeResponse(model: model, context: context)
    }

    @inline(never)
    func transformOneByOneDistribution(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .oneByOneDistribution(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .oneByOne(try getOneByOne(oneByOneModel: model, context: context))
    }

    @inline(never)
    func transformCarouselDistribution(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .carouselDistribution(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .carousel(try getCarousel(carouselModel: model, context: context))
    }

    @inline(never)
    func transformGroupedDistribution(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .groupedDistribution(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .groupDistribution(try getGroupedDistribution(groupedModel: model, context: context))
    }

    @inline(never)
    func transformOverlay(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .overlay(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .overlay(
            try getOverlay(
                model.styles,
                allowBackdropToClose: model.allowBackdropToClose,
                children: transformChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformBottomSheet(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .bottomSheet(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .bottomSheet(
            try getBottomSheet(
                model.styles,
                allowBackdropToClose: model.allowBackdropToClose,
                children: transformChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformWhen(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .when(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .when(
            getWhenNode(
                children: try transformChildren(model.children, context: context),
                predicates: model.predicates,
                transition: model.transition,
                catalogItemContext: context.catalogItemContext,
                predicateOfferIndex: context.offerIndex
            )
        )
    }

    @inline(never)
    func transformStaticLink(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .staticLink(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .staticLink(
            try getStaticLink(
                src: model.src,
                open: model.open,
                styles: model.styles,
                children: transformNonInteractiveChildren(model.children, context: context),
                accessibilityLabel: resolveAccessibilityLabel(model.a11yLabel, context: context)
            )
        )
    }

    @inline(never)
    func transformCloseButton(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .closeButton(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .closeButton(
            try getCloseButton(
                styles: model.styles,
                children: transformNonInteractiveChildren(model.children, context: context),
                dismissalMethod: model.dismissalMethod
            )
        )
    }

    @inline(never)
    func transformProgressControl(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .progressControl(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .progressControl(
            try getProgressControl(
                styles: model.styles,
                direction: model.direction,
                children: transformNonInteractiveChildren(model.children, context: context)
            )
        )
    }

    @inline(never)
    func transformToggleButtonStateTrigger(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .toggleButtonStateTrigger(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .toggleButton(
            try getToggleButton(
                customStateKey: model.customStateKey,
                styles: model.styles,
                children: transformNonInteractiveChildren(model.children, context: context),
                accessibilityLabel: resolveAccessibilityLabel(model.a11yLabel, context: context)
            )
        )
    }

    @inline(never)
    func transformAccessibilityGrouped(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .accessibilityGrouped(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try getAccessibilityGrouped(child: model.child, context: context)
    }

    @inline(never)
    func transformCatalogStackedCollection(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogStackedCollection(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .catalogStackedCollection(try getCatalogStackedCollectionModel(model: model, context: context))
    }

    @inline(never)
    func transformCatalogCombinedCollection(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogCombinedCollection(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .catalogCombinedCollection(try getCatalogCombinedCollection(model: model, context: context))
    }

    @inline(never)
    func transformCatalogResponseButton(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogResponseButton(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .catalogResponseButton(
            try getCatalogResponseButtonModel(
                style: model.styles,
                children: transformNonInteractiveChildren(model.children, context: context),
                context: context,
                responseKey: model.responseKey,
                accessibilityLabel: model.a11yLabel
            )
        )
    }

    @inline(never)
    func transformCatalogDevicePayButton(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogDevicePayButton(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .catalogDevicePayButton(
            try getCatalogDevicePayButton(
                model: model,
                children: transformNonInteractiveChildren(model.children, context: context),
                context: context
            )
        )
    }

    @inline(never)
    func transformCatalogDropdown(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogDropdown(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return .catalogDropdown(
            try getCatalogDropdown(
                model: model,
                attributeIndex: layoutState.nextCatalogDropdownAttributeIndex.advanceAndReturnPrevious()
            )
        )
    }

    @inline(never)
    func transformCatalogImageGallery(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogImageGallery(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try transformWithFallback {
            .catalogImageGallery(try getCatalogImageGallery(model: model, context: context))
        }
    }

    @inline(never)
    func transformInlineContainer(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .inlineContainer(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try withSchemaValidation { .inlineContainer(try getInlineContainer(model, context: context)) }
    }

    @inline(never)
    func transformCatalogCarouselCollection(_ layout: LayoutSchemaModel, context: Context) throws -> LayoutSchemaViewModel {
        guard case .catalogCarouselCollection(let model) = layout else { throw LayoutTransformerError.InvalidMapping() }
        return try withSchemaValidation { .catalogCarouselCollection(try getCatalogCarousel(model, context: context)) }
    }
}
