import Foundation

/// Extracts nested property values from entity `Data` given a sequential chain of property keys in `keys`
protocol DataReflecting {
    func getReflectedValue(data: Mirror, keys: [String]) -> Any?
}

struct DataReflector: DataReflecting {
    func getReflectedValue(data: Mirror, keys: [String]) -> Any? {
        guard let keyToCheck = keys.first else { return nil }

        var targetProperty: Any?

        for child in data.children {
            guard child.label == keyToCheck else { continue }

            if keys.count == 1 {
                targetProperty = child.value

                break
            } else if let valueDict = child.value as? [String: String] {
                // once we hit a dictionary, the assumption is that all remaining keys, EXCLUDING the current key, form a single key
                // we concatenate these using `.` and convert them to a single string

                let remainingKeys = Array(keys.dropFirst())
                let remainingKeysAsString = remainingKeys.joined(separator: BNFSeparator.namespace.rawValue)

                targetProperty = valueDict[remainingKeysAsString]

                break
            } else if let valueDict = child.value as? [String: Any] {
                // support dictionaries with heterogeneous value types
                let remainingKeys = Array(keys.dropFirst())
                let remainingKeysAsString = remainingKeys.joined(separator: BNFSeparator.namespace.rawValue)

                if let directValue = valueDict[remainingKeysAsString] {
                    // existing path: dict key contains the full dotted name
                    // (e.g. copy["provider.discountPercent"])
                    targetProperty = directValue
                } else if remainingKeys.count > 1,
                          let nestedValue = valueDict[remainingKeys[0]] {
                    // dict value is itself a struct/object — recurse into it
                    // with the leftover keys, so e.g. images["catalogItemImage2"].light
                    // resolves through CreativeImage.light.
                    let nestedMirror = Mirror(reflecting: nestedValue)
                    targetProperty = getReflectedValue(
                        data: nestedMirror,
                        keys: Array(remainingKeys.dropFirst())
                    )
                }

                break
            } else {
                // recursion to keep digging into nested properties
                let reflectedChildValue = Mirror(reflecting: child.value)
                let stepThroughKeyList = Array(keys.dropFirst())

                targetProperty = getReflectedValue(data: reflectedChildValue, keys: stepThroughKeyList)
            }
        }

        return targetProperty
    }
}
