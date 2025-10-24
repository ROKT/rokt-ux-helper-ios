import XCTest
import DcuiSchema
@testable import RoktUXHelper

@available(iOS 15, *)
@MainActor
final class CatalogImageGalleryViewModelTests: XCTestCase {

    func test_selectImage_updatesSelectedIndexWhenValid() {
        let viewModel = makeViewModel(imageCount: 3)

        XCTAssertEqual(viewModel.selectedIndex, 0)

        viewModel.selectImage(at: 2)

        XCTAssertEqual(viewModel.selectedIndex, 2)

        viewModel.selectImage(at: 5)

        XCTAssertEqual(viewModel.selectedIndex, 2)
    }

    func test_selectNextImage_advancesWhenPossible() {
        let viewModel = makeViewModel(imageCount: 3)

        viewModel.selectImage(at: 1)
        viewModel.selectNextImage()

        XCTAssertEqual(viewModel.selectedIndex, 2)

        viewModel.selectNextImage()

        XCTAssertEqual(viewModel.selectedIndex, 2)
    }

    func test_selectPreviousImage_advancesWhenPossible() {
        let viewModel = makeViewModel(imageCount: 3)

        viewModel.selectImage(at: 1)
        viewModel.selectPreviousImage()

        XCTAssertEqual(viewModel.selectedIndex, 0)

        viewModel.selectPreviousImage()

        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    func test_selectedImage_matchesCurrentIndex() {
        let first = DataImageViewModel(
            image: nil,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            layoutState: nil
        )
        let second = DataImageViewModel(
            image: nil,
            defaultStyle: nil,
            pressedStyle: nil,
            hoveredStyle: nil,
            disabledStyle: nil,
            layoutState: nil
        )

        let viewModel = CatalogImageGalleryViewModel(
            images: [first, second],
            defaultStyle: nil,
            thumbnailStyle: nil,
            selectedThumbnailStyle: nil,
            thumbnailRowStyle: nil,
            scrollGradientLength: nil,
            leftScrollIcon: nil,
            rightScrollIcon: nil,
            indicatorStyle: nil,
            activeIndicatorStyle: nil,
            seenIndicatorStyle: nil,
            progressIndicatorContainer: nil,
            layoutState: nil
        )

        XCTAssertTrue(viewModel.selectedImage === first)

        viewModel.selectImage(at: 1)

        XCTAssertTrue(viewModel.selectedImage === second)
    }

    func test_imagesUpdate_clampsSelectedIndexWithinBounds() {
        let viewModel = makeViewModel(imageCount: 3)

        viewModel.selectImage(at: 2)
        viewModel.images = Array(viewModel.images.prefix(1))

        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertTrue(viewModel.selectedImage === viewModel.images.first)
    }

    func test_showThumbnails_isTrueWhenThumbnailRowProvided() {
        let rowStyle = basicRowStyle()
        let viewModel = makeViewModel(
            imageCount: 1,
            thumbnailRowStyle: [rowStyle]
        )

        XCTAssertTrue(viewModel.showThumbnails)
    }

    func test_showThumbnails_isFalseWhenThumbnailRowMissing() {
        let viewModel = makeViewModel(imageCount: 1)

        XCTAssertFalse(viewModel.showThumbnails)
    }

    func test_showIndicator_isTrueWhenProgressContainerProvided() {
        let progressContainer = basicIndicatorStyle()
        let viewModel = makeViewModel(
            imageCount: 1,
            progressIndicatorContainer: progressContainer
        )

        XCTAssertTrue(viewModel.showIndicator)
    }

    func test_indicatorAlignSelf_usesProgressContainerAlignment() {
        let progressContainer = basicIndicatorStyle(alignSelf: .flexEnd)
        let viewModel = makeViewModel(
            imageCount: 1,
            progressIndicatorContainer: progressContainer
        )

        XCTAssertEqual(viewModel.indicatorAlignSelf(for: 0), .flexEnd)
    }

    private func makeViewModel(
        imageCount: Int,
        thumbnailRowStyle: [BasicStateStylingBlock<RowStyle>]? = nil,
        progressIndicatorContainer: [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>]? = nil
    ) -> CatalogImageGalleryViewModel {
        let images = (0..<imageCount).map { _ in
            DataImageViewModel(
                image: nil,
                defaultStyle: nil,
                pressedStyle: nil,
                hoveredStyle: nil,
                disabledStyle: nil,
                layoutState: nil
            )
        }

        return CatalogImageGalleryViewModel(
            images: images,
            defaultStyle: nil,
            thumbnailStyle: nil,
            selectedThumbnailStyle: nil,
            thumbnailRowStyle: thumbnailRowStyle,
            scrollGradientLength: nil,
            leftScrollIcon: nil,
            rightScrollIcon: nil,
            indicatorStyle: nil,
            activeIndicatorStyle: nil,
            seenIndicatorStyle: nil,
            progressIndicatorContainer: progressIndicatorContainer,
            layoutState: nil
        )
    }

    private func basicRowStyle() -> BasicStateStylingBlock<RowStyle> {
        BasicStateStylingBlock(
            default: RowStyle(
                container: nil,
                background: nil,
                border: nil,
                dimension: nil,
                flexChild: nil,
                spacing: nil
            ),
            pressed: nil,
            hovered: nil,
            disabled: nil
        )
    }

    private func basicIndicatorStyle(alignSelf: FlexAlignment? = nil)
        -> [BasicStateStylingBlock<CatalogImageGalleryIndicatorStyles>] {
        let flexChild = alignSelf.map { FlexChildStylingProperties(weight: nil, order: nil, alignSelf: $0) }
        let style = CatalogImageGalleryIndicatorStyles(
            container: nil,
            background: nil,
            border: nil,
            dimension: nil,
            flexChild: flexChild,
            spacing: nil
        )
        return [
            BasicStateStylingBlock(
                default: style,
                pressed: nil,
                hovered: nil,
                disabled: nil
            )
        ]
    }
}
