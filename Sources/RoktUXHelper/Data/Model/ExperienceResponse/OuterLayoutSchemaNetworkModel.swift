import Foundation
import DcuiSchema

@available(iOS 13, *)
struct OuterLayoutSchemaNetworkModel: Decodable {
    let breakpoints: BreakPoint?
    let layout: LayoutSchemaModel?
    let settings: LayoutSettings?
}

@available(iOS 13, *)
struct OuterLayoutSchemaValidationModel: Decodable {
    let breakpoints: BreakPoint?
    let layout: OuterLayoutSchemaModel?
    let settings: LayoutSettings?
}
