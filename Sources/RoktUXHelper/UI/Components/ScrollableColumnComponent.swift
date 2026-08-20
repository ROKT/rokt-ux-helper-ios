import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct ScrollableColumnComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let config: ComponentConfig
    let model: ColumnViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    @State private var availableWidth: CGFloat?
    @State private var availableHeight: CGFloat?
    @State private var contentHeight: CGFloat?
    @State private var contentMaxHeight: CGFloat?
    @State private var contentAlignment: Alignment = .center // SwiftUI default frame alignment

    var style: ColumnStyle? {
        switch styleState {
        case .hovered:
            return model.hoveredStyle?.count ?? -1 > breakpointIndex ? model.hoveredStyle?[breakpointIndex] : nil
        case .pressed:
            return model.pressedStyle?.count ?? -1 > breakpointIndex ? model.pressedStyle?[breakpointIndex] : nil
        case .disabled:
            return model.disabledStyle?.count ?? -1 > breakpointIndex ? model.disabledStyle?[breakpointIndex] : nil
        default:
            return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
        }
    }

    @State var breakpointIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }

    let parentOverride: ComponentParentOverride?

    var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.justifyContent?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.alignItems?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var weightProperties: WeightModifier.Properties {
        WeightModifier.Properties(weight: flexStyle?.weight,
                                  parent: .column,
                                  verticalAlignment: verticalAlignment.getAlignment(),
                                  horizontalAlignment: horizontalAlignment.getAlignment())
    }

    private var heightModifier: HeightModifier {
        HeightModifier(
            heightProperty: dimensionStyle?.height,
            minimum: dimensionStyle?.minHeight,
            maximum: dimensionStyle?.maxHeight,
            alignment: verticalAlignment.getAlignment(),
            defaultHeight: .wrapContent,
            parentHeight: parentHeight
        )
    }

    var dimensionMinHeight: CGFloat? {
        heightModifier.frameMinHeight
    }

    var dimensionMaxHeight: CGFloat? {
        return heightModifier.frameMaxHeight
    }

    var dimensionFixedHeight: CGFloat? {
        heightModifier.fixedHeight
    }

    var dimensionPercentageHeight: CGFloat? {
        let margin = style?.spacing?.margin.map {
            FrameAlignmentProperty.getFrameAlignment($0)
        }
        let percentageHeight = PercentageHeightModifier(
            height: parentHeight,
            percentage: dimensionStyle?.height,
            verticalAxisAlignment: verticalAlignment.getAlignment(),
            margin: margin
        )
        return percentageHeight.frameHeight
    }

    var body: some View {
        ScrollView(.vertical) {
            ColumnComponent(config: config,
                            model: model,
                            parentWidth: $parentWidth,
                            parentHeight: $parentHeight,
                            styleState: $styleState,
                            parentOverride: parentOverride,
                            appliesVerticalSizeConstraints: false)
            .readSize(weightProperties: weightProperties) { newSizeWithMax, newAlignment in
                // Dimension sizing belongs to the ScrollView viewport. Its content must
                // remain unconstrained so it can define the scrollable range.
                if let fixedHeight = dimensionFixedHeight {
                    contentMaxHeight = nil
                    contentHeight = fixedHeight
                } else if let percentageHeight = dimensionPercentageHeight {
                    contentMaxHeight = nil
                    contentHeight = percentageHeight
                } else if let dimensionMax = dimensionMaxHeight {
                    contentMaxHeight = dimensionMax
                    contentHeight = nil
                } else if let weightMaxHeight = newSizeWithMax.maxHeight {
                    contentMaxHeight = weightMaxHeight
                    contentHeight = nil
                } else {
                    contentMaxHeight = nil
                    contentHeight = newSizeWithMax.size.height
                }

                contentAlignment = newAlignment
            }
        }
        .frame(height: contentHeight, alignment: contentAlignment)
        .frame(minHeight: dimensionMinHeight,
               maxHeight: contentMaxHeight,
               alignment: contentAlignment)
    }
}
