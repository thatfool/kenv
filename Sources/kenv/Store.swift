import Foundation

/// Encapsulates a set of environment variables.
struct Store: Sendable {
    private var variables: [String: String] = [:]

    init() {}

    init(variables: [String: String]) {
        self.variables = variables
    }

    /// Set a variable.
    mutating func set(_ name: String, value: String) {
        variables[name] = value
    }

    /// Retrieve a variable.
    func get(_ name: String) -> String? {
        variables[name]
    }

    /// Unset a variable.
    mutating func unset(_ name: String) {
        variables.removeValue(forKey: name)
    }

    /// Return the names of all variables in the store.
    var variableNames: [String] {
        Array(variables.keys)
    }

    /// Return all variables in the store.
    var allVariables: [String: String] {
        variables
    }

    /// Return true if there are no variables in the store.
    var isEmpty: Bool {
        variables.isEmpty
    }

    /// Serialize the store to JSON.
    func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(variables)
        return String(data: data, encoding: .utf8)!
    }

    /// Read the content of the store from JSON.
    static func fromJSON(_ json: String) throws -> Store {
        let decoder = JSONDecoder()
        let data = json.data(using: .utf8)!
        let variables = try decoder.decode([String: String].self, from: data)
        return Store(variables: variables)
    }
}
