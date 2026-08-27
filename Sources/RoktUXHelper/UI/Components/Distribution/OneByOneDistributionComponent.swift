import SwiftUI
import DcuiSchema

@available(iOS 15, *)
struct OneByOneDistributionComponent: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    var style: OneByOneDistributionStyles? {
        return model.defaultStyle?.count ?? -1 > breakpointIndex ? model.defaultStyle?[breakpointIndex] : nil
    }

    @EnvironmentObject var globalScreenSize: GlobalScreenSize
    @State var breakpointIndex = 0
    @State var frameChangeIndex: Int = 0

    var containerStyle: ContainerStylingProperties? { style?.container }
    var dimensionStyle: DimensionStylingProperties? { style?.dimension }
    var flexStyle: FlexChildStylingProperties? { style?.flexChild }
    var borderStyle: BorderStylingProperties? { style?.border }
    var spacingStyle: SpacingStylingProperties? { style?.spacing }
    var backgroundStyle: BackgroundStylingProperties? { style?.background }

    var transition: DcuiSchema.Transition? { model.transition }

    let config: ComponentConfig
    let model: OneByOneViewModel

    @Binding var parentWidth: CGFloat?
    @Binding var parentHeight: CGFloat?
    @Binding var styleState: StyleState

    @State private var storedCurrentOffer: Int
    @State private var toggleTransition = false
    @State var customStateMap: RoktUXCustomStateMap?

    var currentOffer: Int {
        get { Self.clampedOfferIndex(storedCurrentOffer, childCount: model.children?.count ?? 0) }
        nonmutating set { storedCurrentOffer = Self.clampedOfferIndex(newValue, childCount: model.children?.count ?? 0) }
    }

    var accessibilityAnnouncement: String {
        String(format: kOneByOneAnnouncement,
               currentOffer + 1,
               model.children?.count ?? 1)
    }

    let parentOverride: ComponentParentOverride?

    var passableBackgroundStyle: BackgroundStylingProperties? {
        backgroundStyle ?? parentOverride?.parentBackgroundStyle
    }

    init(
        config: ComponentConfig,
        model: OneByOneViewModel,
        parentWidth: Binding<CGFloat?>,
        parentHeight: Binding<CGFloat?>,
        styleState: Binding<StyleState>,
        parentOverride: ComponentParentOverride?
    ) {
        self.config = config
        _parentWidth = parentWidth
        _parentHeight = parentHeight
        _styleState = styleState

        self.parentOverride = parentOverride
        self.model = model
        _storedCurrentOffer = State(wrappedValue: Self.clampedOfferIndex(model.initialCurrentIndex ?? 0,
                                                                         childCount: model.children?.count ?? 0))
        _customStateMap = State(wrappedValue: model.initialCustomStateMap ?? RoktUXCustomStateMap())
    }

    private static func clampedOfferIndex(_ index: Int, childCount: Int) -> Int {
        min(max(index, 0), max(childCount - 1, 0))
    }

    var verticalAlignment: VerticalAlignmentProperty {
        if let justifyContent = containerStyle?.alignItems?.asVerticalAlignmentProperty {
            return justifyContent
        } else if let parentAlign = parentOverride?.parentVerticalAlignment?.asVerticalAlignmentProperty {
            return parentAlign
        } else {
            return .top
        }
    }

    var horizontalAlignment: HorizontalAlignmentProperty {
        if let alignItems = containerStyle?.justifyContent?.asHorizontalAlignmentProperty {
            return alignItems
        } else if let parentAlign = parentOverride?.parentHorizontalAlignment?.asHorizontalAlignmentProperty {
            return parentAlign
        } else {
            return .start
        }
    }

    var body: some View {
        if let children = model.children, !children.isEmpty {
            let safeCurrentOffer = currentOffer
            Group {
                LayoutSchemaComponent(config: config.updatePosition(safeCurrentOffer),
                                      layout: children[safeCurrentOffer],
                                      parentWidth: $parentWidth,
                                      parentHeight: $parentHeight,
                                      styleState: $styleState,
                                      parentOverride: parentOverride?.updateBackground(passableBackgroundStyle))
                .applyLayoutModifier(verticalAlignmentProperty: verticalAlignment,
                                     horizontalAlignmentProperty: horizontalAlignment,
                                     spacing: spacingStyle,
                                     dimension: dimensionStyle,
                                     flex: flexStyle,
                                     border: borderStyle,
                                     background: backgroundStyle,
                                     parent: config.parent,
                                     parentWidth: $parentWidth,
                                     parentHeight: $parentHeight,
                                     parentOverride: parentOverride?.updateBackground(passableBackgroundStyle),
                                     defaultHeight: .wrapContent,
                                     defaultWidth: .wrapContent,
                                     isContainer: true,
                                     frameChangeIndex: $frameChangeIndex,
                                     imageLoader: model.imageLoader)
                .opacity(getOpacity())
                .onLoad {
                    registerActions()
                    toggleTransition = true
                    model.sendImpressionEvents(currentOffer: currentOffer)
                    UIAccessibility.post(notification: .announcement,
                                         argument: accessibilityAnnouncement)
                }
                .onChange(of: currentOffer) { newValue in
                    model.publishVisibleOfferIndexes(firstIndex: newValue)
                    model.layoutState?.capturePluginViewState(offerIndex: newValue, dismiss: false)
                    transitionIn()
                    model.sendImpressionEvents(currentOffer: newValue)
                    UIAccessibility.post(notification: .announcement,
                                         argument: accessibilityAnnouncement)
                }
                .onChange(of: customStateMap) { _ in
                    model.layoutState?.capturePluginViewState(offerIndex: nil, dismiss: false)
                }
                .onChange(of: globalScreenSize.width) { newSize in
                    DispatchQueue.main.async {
                        breakpointIndex = model.updateBreakpointIndex(for: newSize)
                        frameChangeIndex += 1
                    }
                }
                .onBecomingViewed(currentOffer: currentOffer) { visibilityInfo in
                    if visibilityInfo.isInViewAndCorrectSize {
                        model.sendCreativeViewedEvent(currentOffer: currentOffer)
                    }
                }
                .onUserInteraction {
                    model.sendCreativeViewedEvent(currentOffer: currentOffer)
                }
            }
        }
    }

    func registerActions() {
        model.layoutState?.actionCollection[.progressControlPrevious] = goToPreviousOffer
        model.layoutState?.actionCollection[.progressControlNext] = goToNextOffer
        model.layoutState?.actionCollection[.nextOffer] = goToNextOffer
        model.layoutState?.actionCollection[.toggleCustomState] = toggleCustomState
        model.setupBindings(
            currentProgess: Binding(get: { currentOffer }, set: { currentOffer = $0 }),
            customStateMap: $customStateMap,
            totalItems: model.children?.count ?? 0
        )
        model.publishVisibleOfferIndexes(firstIndex: currentOffer)
    }

    func goToNextOffer(_: Any? = nil) {
        guard let children = model.children, !children.isEmpty else { return }
        if currentOffer + 1 < children.count {
            transitionToNextOffer()
        } else if model.layoutState?.closeOnComplete() == true {
            // when on last offer AND closeOnComplete is true
            if case .embeddedLayout = model.layoutState?.layoutType() {
                model.sendDismissalCollapsedEvent()
            } else {
                model.sendDismissalNoMoreOfferEvent()
            }

            exit()
        }
    }

    func goToPreviousOffer(_: Any? = nil) {
        if currentOffer > 0 {
            transitionToPreviousOffer()
        }
    }

    func exit() {
        model.layoutState?.actionCollection[.close](nil)
    }

    func transitionIn() {
        switch transition {
        case .fadeInOut(let settings):
            let duration = Double(settings.duration)/1000/2
            withAnimation(
                .easeIn(duration: Double(duration))
            ) {
                toggleTransition = true
            }
        default:
            return
        }
    }

    func transitionToNextOffer() {
        switch transition {
        case .fadeInOut(let settings):
            let duration = Double(settings.duration)/1000/2
            withAnimation(.easeOut(duration: duration)) {
                toggleTransition = false
            }

            // Wait to complete fade out of previous offer
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                incrementCurrentOffer()
            }
        default:
            incrementCurrentOffer()
        }
    }

    func transitionToPreviousOffer() {
        switch transition {
        case .fadeInOut(let settings):
            let duration = Double(settings.duration)/1000/2
            withAnimation(.easeOut(duration: duration)) {
                toggleTransition = false
            }

            // Wait to complete fade out of previous offer
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                decrementCurrentOffer()
            }
        default:
            decrementCurrentOffer()
        }
    }

    private func incrementCurrentOffer() {
        customStateMap = RoktUXCustomStateMap()
        currentOffer += 1
        model.publishVisibleOfferIndexes(firstIndex: currentOffer)
    }

    private func decrementCurrentOffer() {
        customStateMap = RoktUXCustomStateMap()
        currentOffer -= 1
        model.publishVisibleOfferIndexes(firstIndex: currentOffer)
    }

    private func toggleCustomState(_ customStateId: Any?) {
        var mutatingCustomStateMap: RoktUXCustomStateMap = customStateMap ?? RoktUXCustomStateMap()
        self.customStateMap = mutatingCustomStateMap.toggleValueFor(customStateId)
        model.publishStateChange()
    }

    func getOpacity() -> Double {
        switch transition {
        case .fadeInOut:
            return toggleTransition ? 1 : 0
        default:
            return 1
        }
    }
}
