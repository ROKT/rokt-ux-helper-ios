import XCTest
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

    private func makeViewModel(imageCount: Int) -> CatalogImageGalleryViewModel {
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
            thumbnailRowStyle: nil,
            scrollGradientLength: nil,
            leftScrollIcon: nil,
            rightScrollIcon: nil,
            layoutState: nil
        )
    }
}
