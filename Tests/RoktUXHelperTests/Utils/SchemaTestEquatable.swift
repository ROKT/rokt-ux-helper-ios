@testable import RoktUXHelper
import DcuiSchema

// Test-only Equatable conformances for schema types whose Equatable was
// dropped from DcuiSchema to shrink the SDK binary. These extensions live
// in the test target only — production code never compares these as whole
// structs. Manual `==` implementations because Swift cannot auto-synthesise
// Equatable in a different module from the type's declaration.

extension DimensionWidthValue: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.fixed(let l), .fixed(let r)): return l == r
        case (.percentage(let l), .percentage(let r)): return l == r
        case (.fit(let l), .fit(let r)): return l == r
        default: return false
        }
    }
}

extension BackgroundImage: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url
            && lhs.position == rhs.position
            && lhs.scale == rhs.scale
    }
}

extension BackgroundStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.backgroundColor == rhs.backgroundColor
            && lhs.backgroundImage == rhs.backgroundImage
    }
}

extension BorderStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.borderRadius == rhs.borderRadius
            && lhs.borderColor == rhs.borderColor
            && lhs.borderWidth == rhs.borderWidth
            && lhs.borderStyle == rhs.borderStyle
    }
}

extension Shadow: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.offsetX == rhs.offsetX
            && lhs.offsetY == rhs.offsetY
            && lhs.blurRadius == rhs.blurRadius
            && lhs.spreadRadius == rhs.spreadRadius
            && lhs.color == rhs.color
    }
}

extension ContainerStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.justifyContent == rhs.justifyContent
            && lhs.alignItems == rhs.alignItems
            && lhs.shadow == rhs.shadow
            && lhs.overflow == rhs.overflow
            && lhs.gap == rhs.gap
            && lhs.blur == rhs.blur
    }
}

extension ZStackContainerStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.justifyContent == rhs.justifyContent
            && lhs.alignItems == rhs.alignItems
            && lhs.shadow == rhs.shadow
            && lhs.overflow == rhs.overflow
            && lhs.blur == rhs.blur
    }
}

extension DimensionStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.minWidth == rhs.minWidth
            && lhs.maxWidth == rhs.maxWidth
            && lhs.width == rhs.width
            && lhs.minHeight == rhs.minHeight
            && lhs.maxHeight == rhs.maxHeight
            && lhs.height == rhs.height
            && lhs.rotateZ == rhs.rotateZ
    }
}

extension FlexChildStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.weight == rhs.weight
            && lhs.order == rhs.order
            && lhs.alignSelf == rhs.alignSelf
    }
}

extension SpacingStylingProperties: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.padding == rhs.padding
            && lhs.margin == rhs.margin
            && lhs.offset == rhs.offset
    }
}

extension CreativeResponseStyles: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container
            && lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
    }
}

extension BasicTextStyle: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
            && lhs.background == rhs.background
            && lhs.text == rhs.text
    }
}

extension ColumnStyle: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container
            && lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
    }
}

extension ZStackStyle: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container
            && lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
    }
}

extension StaticLinkStyles: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container
            && lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
    }
}

extension ToggleButtonStateTriggerStyle: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container
            && lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
    }
}

extension BaseStyles: @retroactive Equatable {
    public static func == (lhs: BaseStyles, rhs: BaseStyles) -> Bool {
        lhs.background == rhs.background
            && lhs.border == rhs.border
            && lhs.container == rhs.container
            && lhs.dimension == rhs.dimension
            && lhs.flexChild == rhs.flexChild
            && lhs.spacing == rhs.spacing
            && lhs.text == rhs.text
    }
}
