import Foundation

@available(iOS 13, *)
struct RoktDecoder {

    func decode<T: Decodable>(_ type: T.Type, _ string: String) throws -> T {
        try string.data(using: .utf8)
            .flatMap {
                try JSONDecoder().decode(type, from: $0)
            }
            .unwrap(orThrow: RoktUXError.experienceResponseMapping)
    }
}
