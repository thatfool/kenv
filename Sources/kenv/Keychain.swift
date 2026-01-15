import Foundation
@preconcurrency import LocalAuthentication
import Security

protocol KeychainProtocol: Sendable {
    func withAuthentication<T>(_ operation: (AuthenticatedKeychain) throws -> T) throws -> T
    func listServices(withPrefix prefix: String) throws -> [String]
}

protocol AuthenticatedKeychain {
    func save(service: String, data: Data) throws
    func load(service: String) throws -> Data
    func delete(service: String) throws
}

/// Interface to the login keychain.
final class Keychain: KeychainProtocol, Sendable {
    static let shared = Keychain()

    private let account = "kenv"

    private init() {}

    /// Authenticates once and runs the operation with that context.
    func withAuthentication<T>(_ operation: (AuthenticatedKeychain) throws -> T) throws -> T {
        let context = try runBlocking { try await self.authenticate() }
        let session = AuthenticatedSession(account: account, context: context)
        return try operation(session)
    }

    /// Authenticate.
    private func authenticate() async throws -> LAContext {
        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw KeychainError.authenticationFailed(error?.localizedDescription ?? "Authentication not available")
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Access kenv secrets"
                ) { success, evalError in
                if success {
                    continuation.resume(returning: context)
                } else if let laError = evalError as? LAError {
                    if laError.code == .userCancel || laError.code == .appCancel {
                        continuation.resume(throwing: KeychainError.authenticationCancelled)
                    } else {
                        continuation.resume(throwing: KeychainError.authenticationFailed(laError.localizedDescription))
                    }
                } else if let evalError = evalError {
                    continuation.resume(throwing: KeychainError.authenticationFailed(evalError.localizedDescription))
                } else {
                    continuation.resume(throwing: KeychainError.authenticationFailed("Unknown error"))
                }
            }
        }
    }

    /// Utility to run async code from a synchronous context.
    private func runBlocking<T: Sendable>(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: Result<T, Error>?

        Task {
            do {
                result = .success(try await operation())
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()
        return try result!.get()
    }

    /// Retrieve keychain entries with a given prefix.
    func listServices(withPrefix prefix: String) throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return []
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedError(status)
        }

        guard let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let service = item[kSecAttrService as String] as? String,
                  service.hasPrefix(prefix) else {
                return nil
            }
            return String(service.dropFirst(prefix.count))
        }.sorted()
    }
}

/// Encapsulates interaction with the keychain in an authenticated session.
private struct AuthenticatedSession: AuthenticatedKeychain {
    let account: String
    let context: LAContext

    /// Save data to a keychain entry, overwriting existing data.
    func save(service: String, data: Data) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecUseAuthenticationContext as String: context
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedError(status)
        }
    }

    /// Load data from a keychain entry.
    func load(service: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedError(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.encodingError
        }

        return data
    }

    /// Delete a keychain entry.
    func delete(service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseAuthenticationContext as String: context,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedError(status)
        }

        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        }
    }
}

/// An error from an interaction with the keychain.
enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedError(OSStatus)
    case encodingError
    case authenticationFailed(String)
    case authenticationCancelled

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Store not found"
        case .duplicateItem:
            return "Store already exists"
        case .unexpectedError(let status):
            if let message = SecCopyErrorMessageString(status, nil) {
                return message as String
            }
            return "Keychain error: \(status)"
        case .encodingError:
            return "Failed to encode data"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .authenticationCancelled:
            return "Authentication cancelled"
        }
    }
}
