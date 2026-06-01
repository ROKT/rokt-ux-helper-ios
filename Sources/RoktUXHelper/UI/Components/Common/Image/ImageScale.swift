import SwiftUI
import DcuiSchema

@available(iOS 15.0, *)
enum ImageRenderScale: Equatable {
    case crop
    case fit
    case fill

    var contentMode: ContentMode {
        switch self {
        case .fill:
            return .fill
        case .crop, .fit:
            return .fit
        }
    }
}

@available(iOS 15.0, *)
extension BackgroundImageScale {
    var asImageRenderScale: ImageRenderScale {
        switch self {
        case .crop:
            return .crop
        case .fill:
            return .fill
        case .fit:
            return .fit
        }
    }
}

@available(iOS 15.0, *)
extension DcuiSchema.ImageScale {
    var asImageRenderScale: ImageRenderScale {
        switch self {
        case .crop:
            return .crop
        case .fill:
            return .fill
        case .fit:
            return .fit
        }
    }
}
