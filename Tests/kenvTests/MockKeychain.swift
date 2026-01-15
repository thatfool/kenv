import Foundation
@testable import kenv

final class MockKeychain: KeychainProtocol, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func withAuthentication<T>(_ operation: (AuthenticatedKeychain) throws -> T) throws -> T {
        try operation(self)
    }

    func listServices(withPrefix prefix: String) throws -> [String] {
        storage.keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .sorted()
    }

    func clear() {
        storage.removeAll()
    }
}

extension MockKeychain: AuthenticatedKeychain {
    func save(service: String, data: Data) throws {
        storage[service] = data
    }

    func load(service: String) throws -> Data {
        guard let data = storage[service] else {
            throw KeychainError.itemNotFound
        }
        return data
    }

    func delete(service: String) throws {
        guard storage.removeValue(forKey: service) != nil else {
            throw KeychainError.itemNotFound
        }
    }
}
