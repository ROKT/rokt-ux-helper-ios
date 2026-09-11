import DcuiSchema

/// Checks raw children so hidden branches and unexpanded templates cannot introduce nested actions.
enum SchemaInteractionValidation {
    static func validate(_ children: [LayoutSchemaModel], slotSchemas: [LayoutSchemaModel] = []) throws {
        if children.contains(where: { containsNewAction($0, slotSchemas: slotSchemas) }) {
            throw LayoutTransformerError
                .unsupportedFeature("interactive ancestor contains an inline action or CatalogCarouselCollection")
        }
    }

    private static func containsNewAction(_ node: LayoutSchemaModel, slotSchemas: [LayoutSchemaModel]) -> Bool {
        switch node {
        case .catalogCarouselCollection: return true
        case .inlineContainer(let model):
            return model.children.contains { if case .basicText = $0 { return false }; return true }
        case .oneByOneDistribution, .carouselDistribution, .groupedDistribution:
            return slotSchemas.contains { containsNewAction($0, slotSchemas: []) }
        default:
            return children(of: node).contains { containsNewAction($0, slotSchemas: slotSchemas) }
        }
    }

    private static func children(of node: LayoutSchemaModel) -> [LayoutSchemaModel] {
        switch node {
        case .row(let model): return model.children
        case .column(let model): return model.children
        case .scrollableRow(let model): return model.children
        case .scrollableColumn(let model): return model.children
        case .zStack(let model): return model.children
        case .overlay(let model): return model.children
        case .bottomSheet(let model): return model.children
        case .when(let model): return model.children
        case .staticLink(let model): return model.children
        case .closeButton(let model): return model.children
        case .progressControl(let model): return model.children
        case .creativeResponse(let model): return model.children
        case .toggleButtonStateTrigger(let model): return model.children
        case .catalogResponseButton(let model): return model.children
        case .catalogDevicePayButton(let model): return model.children
        case .catalogStackedCollection(let model):
            switch model.template {
            case .row(let row): return row.children
            case .column(let column): return column.children
            }
        case .catalogCombinedCollection(let model):
            switch model.template {
            case .row(let row): return row.children
            case .column(let column): return column.children
            }
        case .staticImage, .dataImage, .dataImageCarousel, .richText, .basicText, .progressIndicator,
             .oneByOneDistribution, .carouselDistribution, .groupedDistribution, .catalogDropdown,
             .catalogImageGallery, .inlineContainer, .catalogCarouselCollection, .accessibilityGrouped:
            return []
        }
    }
}
