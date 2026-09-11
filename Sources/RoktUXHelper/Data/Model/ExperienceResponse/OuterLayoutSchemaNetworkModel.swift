import Foundation
import DcuiSchema

@available(iOS 13, *)
struct OuterLayoutSchemaNetworkModel: Decodable {
    let breakpoints: BreakPoint?
    let layout: LayoutSchemaModel?
    let settings: LayoutSettings?
}
