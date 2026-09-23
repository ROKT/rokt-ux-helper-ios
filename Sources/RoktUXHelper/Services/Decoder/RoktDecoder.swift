import Foundation

@available(iOS 13, *)
struct RoktDecoder {

    func decode<T: Decodable>(_ type: T.Type, _ string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw RoktUXError.experienceResponseMapping
        }

        // Decode on a dedicated thread with an expanded stack so deeply nested but otherwise
        // schema-compatible payloads remain safe to parse.
        return try WideStack.run(named: "com.rokt.decoder") {
            try JSONDecoder().decode(type, from: data)
        }
    }
}
