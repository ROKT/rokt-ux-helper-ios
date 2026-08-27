import DcuiSchema

protocol SchemaRenderableStyle: Decodable {
    var flexChild: FlexChildStylingProperties? { get }
    var schemaShadow: Shadow? { get }
}

extension SchemaRenderableStyle {
    var schemaShadow: Shadow? { nil }
}

extension RowStyle: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension ColumnStyle: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension ZStackStyle: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension StaticLinkStyles: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension ToggleButtonStateTriggerStyle: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension CatalogResponseButtonStyles: SchemaRenderableStyle { var schemaShadow: Shadow? { container?.shadow } }
extension BasicTextStyle: SchemaRenderableStyle {}
extension RichTextStyle: SchemaRenderableStyle {}
extension StaticImageStyles: SchemaRenderableStyle {}
extension DataImageStyles: SchemaRenderableStyle {}

/// Limits validation to new inline and card contexts; legacy layouts retain their existing behavior.
enum SchemaStyleValidation {
    static func validate<T: SchemaRenderableStyle>(_ style: T, node: String) throws {
        if let order = style.flexChild?.order, order != 0 {
            throw LayoutTransformerError.unsupportedFeature("\(node).flexChild.order")
        }
        if let spread = style.schemaShadow?.spreadRadius, spread != 0 {
            throw LayoutTransformerError.unsupportedFeature("\(node).container.shadow.spreadRadius")
        }
        // Validate each raw state and transition, including values that are not currently visible.
        _ = try StyleTransformer.updatedStyle(style, newStyle: nil)
    }

    static func duration(_ value: Int32) throws {
        guard value >= 0 else {
            throw LayoutTransformerError.unsupportedFeature("conditionalTransitions.duration must be nonnegative")
        }
    }
}
