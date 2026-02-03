//
//  ExperimentationError.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - ExperimentationError

/// Errors that can occur when working with the experimentation system.
///
/// All errors conform to `LocalizedError` to provide user-friendly error messages
/// that can be displayed in the UI.
///
/// ## Handling Errors
/// ```swift
/// do {
///     try await facade.initialize()
/// } catch let error as ExperimentationError {
///     // Show user-friendly message
///     showAlert(
///         title: "Feature Flags Unavailable",
///         message: error.errorDescription ?? "Unknown error",
///         suggestion: error.recoverySuggestion
///     )
/// }
/// ```
nonisolated public enum ExperimentationError: LocalizedError, Equatable, Sendable {

    /// The LaunchDarkly SDK failed to initialize.
    /// This typically occurs due to network issues or invalid API key.
    case initializationFailed(reason: String)

    /// An operation was attempted before `initialize()` was called.
    case clientNotInitialized

    /// Failed to update the user context (e.g., after login/logout).
    case identifyFailed(reason: String)

    /// The requested flag key was not found in LaunchDarkly.
    /// This may indicate the flag hasn't been created yet or was deleted.
    case flagNotFound(key: String)

    /// A JSON flag value could not be decoded to the expected type.
    case decodingFailed(key: String, reason: String)

    /// Network is unavailable. Cached flag values will be used.
    case networkUnavailable

    /// The SDK timed out while waiting for flags.
    case timeout

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            "Failed to initialize experimentation service: \(reason)"
        case .clientNotInitialized:
            "Experimentation service has not been initialized. Call initialize() first."
        case .identifyFailed(let reason):
            "Failed to identify user: \(reason)"
        case .flagNotFound(let key):
            "Feature flag '\(key)' was not found."
        case .decodingFailed(let key, let reason):
            "Failed to decode feature flag '\(key)': \(reason)"
        case .networkUnavailable:
            "Network is unavailable. Using cached flag values."
        case .timeout:
            "The request timed out. Using cached flag values."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            "Check your network connection and API key configuration."
        case .clientNotInitialized:
            "Ensure initialize() is called before accessing feature flags."
        case .identifyFailed:
            "Check user credentials and try again."
        case .flagNotFound:
            "Verify the flag key matches the one configured in LaunchDarkly."
        case .decodingFailed:
            "Check that the flag value format matches the expected type."
        case .networkUnavailable:
            "Restore network connection for real-time flag updates."
        case .timeout:
            "Check your network connection and try again."
        }
    }

    public var failureReason: String? {
        switch self {
        case .initializationFailed(let reason):
            reason
        case .clientNotInitialized:
            "The client was not initialized before use."
        case .identifyFailed(let reason):
            reason
        case .flagNotFound(let key):
            "No flag exists with key '\(key)'."
        case .decodingFailed(_, let reason):
            reason
        case .networkUnavailable:
            "No network connection available."
        case .timeout:
            "The operation exceeded the allowed time limit."
        }
    }
}
