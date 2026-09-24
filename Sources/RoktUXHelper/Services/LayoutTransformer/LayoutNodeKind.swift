import Foundation
import DcuiSchema

/// Which kind of node a `LayoutSchemaModel` is, carrying none of its payload.
///
/// `transform` dispatches on this rather than on the model itself. Switching over the model costs
/// stack: at `-Onone` each case arm of a `switch` reserves a slot for the payload it projects out
/// of the `indirect` enum's box — around 400 bytes for the container models and up to about 2.9 KB
/// for the catalog ones — whether or not the arm binds it. Thirty-one arms came to roughly 22 KB,
/// and because `transform` is the recursive step, that was reserved again at every level of
/// nesting. Reading the kind here pays the same 22 KB once, in a frame that has returned before
/// the descent continues.
enum LayoutNodeKind {
    case row
    case column
    case zStack
    case scrollableColumn
    case scrollableRow
    case basicText
    case richText
    case staticImage
    case dataImage
    case dataImageCarousel
    case progressIndicator
    case creativeResponse
    case oneByOneDistribution
    case carouselDistribution
    case groupedDistribution
    case overlay
    case bottomSheet
    case when
    case staticLink
    case closeButton
    case progressControl
    case toggleButtonStateTrigger
    case accessibilityGrouped
    case catalogStackedCollection
    case catalogCombinedCollection
    case catalogResponseButton
    case catalogDevicePayButton
    case catalogDropdown
    case catalogImageGallery
    case inlineContainer
    case catalogCarouselCollection
}

extension LayoutSchemaModel {

    /// The one exhaustive switch over `LayoutSchemaModel` in the transform, so a node kind added to
    /// the schema is a compile error here rather than a layout that silently fails to render.
    @inline(never)
    var nodeKind: LayoutNodeKind {
        switch self {
        case .row: .row
        case .column: .column
        case .zStack: .zStack
        case .scrollableColumn: .scrollableColumn
        case .scrollableRow: .scrollableRow
        case .basicText: .basicText
        case .richText: .richText
        case .staticImage: .staticImage
        case .dataImage: .dataImage
        case .dataImageCarousel: .dataImageCarousel
        case .progressIndicator: .progressIndicator
        case .creativeResponse: .creativeResponse
        case .oneByOneDistribution: .oneByOneDistribution
        case .carouselDistribution: .carouselDistribution
        case .groupedDistribution: .groupedDistribution
        case .overlay: .overlay
        case .bottomSheet: .bottomSheet
        case .when: .when
        case .staticLink: .staticLink
        case .closeButton: .closeButton
        case .progressControl: .progressControl
        case .toggleButtonStateTrigger: .toggleButtonStateTrigger
        case .accessibilityGrouped: .accessibilityGrouped
        case .catalogStackedCollection: .catalogStackedCollection
        case .catalogCombinedCollection: .catalogCombinedCollection
        case .catalogResponseButton: .catalogResponseButton
        case .catalogDevicePayButton: .catalogDevicePayButton
        case .catalogDropdown: .catalogDropdown
        case .catalogImageGallery: .catalogImageGallery
        case .inlineContainer: .inlineContainer
        case .catalogCarouselCollection: .catalogCarouselCollection
        }
    }
}
