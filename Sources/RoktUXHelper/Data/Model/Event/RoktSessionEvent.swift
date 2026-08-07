import Foundation

/// Serialises RoktUXHelper events into the `POST v2/sessions/events` request body,
/// so the payload handed to `onRoktPlatformEvent` can be forwarded to the events API
/// directly, without any further transformation.
struct RoktSessionEventsBody: Encodable {
    struct Channel: Encodable {
        let type: String
    }

    struct Event: Encodable {
        let eventType: String
        let instanceId: String
        let sessionId: String
        let timestamp: Int64
        let data: [String: String]

        enum CodingKeys: String, CodingKey {
            case eventType = "event_type"
            case instanceId = "instance_id"
            case sessionId = "session_id"
            case timestamp
            case data
        }
    }

    let channel: Channel
    /// Pins the whole batch to the synchronous events path so every event lands on the
    /// same session (instead of the async intake path, which mints a fresh session per event).
    let singleSession: Bool
    let events: [Event]

    enum CodingKeys: String, CodingKey {
        case channel
        case singleSession = "single_session"
        case events
    }

    init(events requests: [RoktEventRequest]) {
        channel = Channel(type: kChannelTypeS2S)
        singleSession = true
        events = requests.map(Event.init(from:))
    }
}

private extension RoktSessionEventsBody.Event {
    init(from request: RoktEventRequest) {
        let mapped = request.eventType.registryEventType
        var data = [String: String]()
        request.eventData.forEach { data[$0.name] = $0.value }
        request.objectData?.forEach { data[$0.key] = $0.value }
        request.metadata.forEach { nameValue in
            switch nameValue.name {
            case BE_CLIENT_TIME_STAMP: break // promoted to the top-level timestamp
            case BE_CAPTURE_METHOD: data["capture_method"] = nameValue.value
            default: data[nameValue.name] = nameValue.value
            }
        }
        // parentGuid is already the bare instance_guid (no `type:` prefix).
        data["parent_id"] = request.parentGuid
        data["token"] = request.jwtToken
        if !request.pageInstanceGuid.isEmpty {
            data["page_instance_guid"] = request.pageInstanceGuid
        }
        mapped.extraData.forEach { data[$0.key] = $0.value }

        eventType = mapped.type
        instanceId = request.uuid
        // Canonical envelope field (not part of `data`). Carries the session on the
        // S2S self-forward path, where there is no session JWT to derive it from.
        sessionId = request.sessionId
        timestamp = EventDateFormatter.getMillis(request.eventTime)
        self.data = data
    }
}

private extension RoktUXEventType {
    /// Fixed legacy-enum → Session API event-type string mapping (partner-independent).
    var registryEventType: (type: String, extraData: [String: String]) {
        switch self {
        case .SignalImpression: return ("impression", [:])
        case .SignalViewed: return ("viewed", [:])
        case .SignalResponse: return ("signal_response", [:])
        case .SignalGatedResponse: return ("signal_gated_response", [:])
        case .SignalDismissal: return ("dismissal", [:])
        case .SignalInitialize: return ("signal_initialize", [:])
        case .SignalLoadStart: return ("load_start", [:])
        case .SignalLoadComplete: return ("load_complete", [:])
        case .SignalActivation: return ("user_interaction", ["interactionType": "activation"])
        case .SignalUserInteraction: return ("user_interaction", [:])
        case .SignalSdkDiagnostic: return ("sdk_diagnostic", [:])
        case .SignalCartItemInstantPurchase: return ("cart_item_instant_purchase", [:])
        case .SignalCartItemInstantPurchaseFailure: return ("cart_item_instant_purchase_failure", [:])
        case .SignalCartItemInstantPurchaseInitiated: return ("cart_item_instant_purchase_initiated", [:])
        case .SignalInstantPurchaseDismissal: return ("instant_purchase_dismissal", [:])
        case .CaptureAttributes: return ("capture_attributes", [:])
        }
    }
}

private let kChannelTypeS2S = "s2s"
