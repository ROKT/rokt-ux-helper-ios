import Foundation
import DcuiSchema

/// A style type whose breakpoint and state merge is wired into `StyleTransformer`.
///
/// Conformance is what makes a style merge: `StyleTransformer.updatedStyle` returns `nil` for a type
/// that has none, which silently drops breakpoint inheritance and every authored pressed, hovered,
/// focussed and disabled state. Constrain generic call sites to `StyleMergeable` wherever the
/// constraint can be threaded, so a style type nobody wired in fails to compile instead.
protocol StyleMergeable: Decodable {
    /// Returns `base` with each property `override` supplies replacing the corresponding one.
    static func merging(_ base: Self, _ override: Self?) throws -> Self
}

extension StyleMergeable {
    /// Reaches `merging` from a call site that only knows the style is `Decodable`, by opening the
    /// existential the caller obtained with `as? any StyleMergeable`.
    func merged(with override: Any?) throws -> Self {
        try Self.merging(self, override.flatMap { $0 as? Self })
    }
}

// MARK: - Conformances

// Each merge lives in the matching `StyleTransformer.getUpdatedStyle` overload; these declare which
// types reach it. Adding a style type to the pipeline means adding it here too.

// A class cannot name `Self` in parameter position, so this one conformance spells out the type.
extension StylingPropertiesModel: StyleMergeable {
    static func merging(_ base: StylingPropertiesModel,
                        _ override: StylingPropertiesModel?) throws -> StylingPropertiesModel {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension RowStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ScrollableRowStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ColumnStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ScrollableColumnStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ZStackStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension OneByOneDistributionStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension BasicTextStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension RichTextStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension StaticImageStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension DataImageStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension CloseButtonStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension IndicatorStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ProgressIndicatorStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension InLineTextStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension StaticLinkStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension CreativeResponseStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ProgressControlStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension GroupedDistributionStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension ToggleButtonStateTriggerStyle: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension DataImageCarouselStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension DataImageCarouselIndicatorStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension CatalogDevicePayButtonStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}

extension CatalogResponseButtonStyles: StyleMergeable {
    static func merging(_ base: Self, _ override: Self?) throws -> Self {
        try StyleTransformer.getUpdatedStyle(base, newStyle: override)
    }
}
