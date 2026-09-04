import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct CatalogCarouselCollectionComponent: View {
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @ObservedObject var model: CatalogCarouselCollectionViewModel
    let config: ComponentConfig
    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState
    let parentOverride: ComponentParentOverride?
    @State private var frameChangeIndex = 0

    init(config: ComponentConfig, model: CatalogCarouselCollectionViewModel,
         parentWidth: Binding<CGFloat?>, parentHeight: Binding<CGFloat?>,
         styleState: Binding<StyleState>, parentOverride: ComponentParentOverride?) {
        self.config = config
        self.model = model
        self._parentWidth = parentWidth
        self._parentHeight = parentHeight
        self._styleState = styleState
        self.parentOverride = parentOverride
    }

    private var breakpointIndex: Int { model.layoutState?.getGlobalBreakpointIndex(globalScreenSize.width) ?? 0 }
    private var style: BaseStyles? { model.style(width: globalScreenSize.width, position: config.position,
                                                 colorScheme: colorScheme) }
    private var background: BackgroundStylingProperties? { style?.background ?? parentOverride?.parentBackgroundStyle }
    private var isInteractionEnabled: Bool { isEnabled && styleState != .disabled }

    var body: some View {
        if !model.cards.isEmpty {
            GeometryReader { proxy in
                let geometry = model.geometry(viewportWidth: proxy.size.width, breakpointIndex: breakpointIndex, style: style)
                CatalogCarouselScrollHost(model: model, geometry: geometry, isEnabled: isInteractionEnabled,
                                          content: cards(geometry: geometry)
                                            .environmentObject(globalScreenSize)
                                            .disabled(!isInteractionEnabled))
                    .id(model.id)
            }
            .frame(height: model.contentHeight ?? 1)
            .applyLayoutModifier(verticalAlignmentProperty: .top,
                                 horizontalAlignmentProperty: .start,
                                 spacing: style?.spacing,
                                 dimension: style?.dimension,
                                 flex: style?.flexChild,
                                 border: style?.border,
                                 background: style?.background,
                                 container: style?.container,
                                 parent: config.parent,
                                 parentWidth: $parentWidth,
                                 parentHeight: $parentHeight,
                                 parentOverride: parentOverride?.updateBackground(background),
                                 defaultHeight: .wrapContent,
                                 defaultWidth: .fitWidth,
                                 isContainer: true,
                                 containerType: .row,
                                 frameChangeIndex: $frameChangeIndex,
                                 imageLoader: model.imageLoader)
            .onChange(of: globalScreenSize.width) { _ in frameChangeIndex += 1 }
            .animation(.linear(duration: max(0, model.conditionalStyle?.animation.duration ?? 0)),
                       value: model.conditionalStyle?.applies(position: config.position, width: globalScreenSize.width ?? 0,
                                                              colorScheme: colorScheme) ?? false)
        }
    }

    private func cards(geometry: CatalogCarouselGeometry) -> some View {
        HStack(alignment: rowPerpendicularAxisAlignment(alignItems: style?.container?.alignItems), spacing: geometry.gap) {
            ForEach(model.cards) { card in
                LayoutSchemaComponent(config: config.updateParent(.row).updatePosition(card.context.offerIndex),
                                      layout: card.layout,
                                      parentWidth: .constant(geometry.itemWidth),
                                      parentHeight: .constant(nil),
                                      styleState: $styleState,
                                      parentOverride: ComponentParentOverride(parentVerticalAlignment: .top,
                                                                              parentHorizontalAlignment: .leading,
                                                                              parentBackgroundStyle: background,
                                                                              stretchChildren: true))
                    .frame(width: geometry.itemWidth)
                    .readSize { size in
                        model.recordHeight(size.height, itemIndex: card.context.itemIndex, itemWidth: geometry.itemWidth)
                    }
                    .accessibilityElement(children: .contain)
            }
        }
        .frame(width: max(geometry.viewportWidth, geometry.contentWidth), alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
