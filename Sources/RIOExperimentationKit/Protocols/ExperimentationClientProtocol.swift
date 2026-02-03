//
//  ExperimentationClientProtocol.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - ExperimentationClientProtocol

/// Protocol for the underlying experimentation client that communicates with LaunchDarkly.
///
/// This protocol abstracts the LaunchDarkly SDK, allowing for mock implementations
/// during testing and previews.
///
/// ## Implementation Notes
/// - Implementations must be thread-safe (use `actor`)
/// - The `flagStream` should emit updates whenever flags change
/// - Handle network errors gracefully and use cached values when offline
public protocol ExperimentationClientProtocol: Sendable {

    /// Initializes the client and establishes connection to LaunchDarkly.
    ///
    /// - Throws: `ExperimentationError.initializationFailed` if connection fails
    func initialize() async throws

    /// Explicitly refreshes all flag values from LaunchDarkly.
    ///
    /// Call this when you want to force-update deferred flags.
    func refresh() async throws

    /// Updates the user context for flag evaluation.
    ///
    /// Call this when the user logs in, logs out, or changes identity.
    ///
    /// - Parameter state: The new user state
    /// - Throws: `ExperimentationError.identifyFailed` if the context update fails
    func handleUserStateChange(_ state: ExperimentationUserState) async throws

    /// Returns the current value for a boolean flag.
    ///
    /// - Parameters:
    ///   - key: The flag key in LaunchDarkly
    ///   - defaultValue: Value to return if flag is not found
    /// - Returns: The flag value or default
    func boolValue(forKey key: String, defaultValue: Bool) async -> Bool

    /// Returns the current value for a string flag.
    ///
    /// - Parameters:
    ///   - key: The flag key in LaunchDarkly
    ///   - defaultValue: Value to return if flag is not found
    /// - Returns: The flag value or default
    func stringValue(forKey key: String, defaultValue: String) async -> String

    /// Returns the current value for a double flag.
    ///
    /// - Parameters:
    ///   - key: The flag key in LaunchDarkly
    ///   - defaultValue: Value to return if flag is not found
    /// - Returns: The flag value or default
    func doubleValue(forKey key: String, defaultValue: Double) async -> Double

    /// Returns the current value for a JSON flag as raw data.
    ///
    /// - Parameter key: The flag key in LaunchDarkly
    /// - Returns: The JSON data or nil if not found
    func jsonData(forKey key: String) async -> Data?

    /// Stream of flag update events for real-time updates.
    ///
    /// Implementations should emit events whenever LaunchDarkly pushes flag changes.
    /// The stream should include the flag key and new value.
    var flagUpdateStream: AsyncStream<FlagUpdate> { get }
}


// MARK: - FlagUpdate

/// Represents a real-time flag update from LaunchDarkly.
public struct FlagUpdate: Sendable {

    /// The key of the flag that changed.
    public let key: String

    /// When the update was received.
    public let receivedAt: Date

    public init(key: String, receivedAt: Date = Date()) {
        self.key = key
        self.receivedAt = receivedAt
    }
}
