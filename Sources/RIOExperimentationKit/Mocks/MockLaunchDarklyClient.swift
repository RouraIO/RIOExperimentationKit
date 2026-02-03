//
//  MockLaunchDarklyClient.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - MockLaunchDarklyClient

/// A mock implementation of `ExperimentationClientProtocol` for testing and previews.
///
/// This mock returns configurable default values and doesn't communicate with
/// any external service. Use it for:
/// - SwiftUI Previews
/// - Unit tests
/// - UI tests
///
/// ## Customizing Values
/// You can configure the mock to return specific values:
/// ```swift
/// let mock = MockLaunchDarklyClient()
/// mock.boolValues["myFlag"] = true
/// mock.stringValues["variant"] = "treatment"
/// ```
public final class MockLaunchDarklyClient: ExperimentationClientProtocol, @unchecked Sendable {

    // MARK: - Configurable Values

    /// Boolean flag values to return. Key is flag key, value is the flag value.
    public var boolValues: [String: Bool] = [:]

    /// String flag values to return.
    public var stringValues: [String: String] = [:]

    /// Double flag values to return.
    public var doubleValues: [String: Double] = [:]

    /// JSON data values to return.
    public var jsonDataValues: [String: Data] = [:]

    // MARK: - State

    public private(set) var initializeCalled = false
    public private(set) var refreshCalled = false
    public private(set) var lastUserState: ExperimentationUserState?

    // MARK: - Flag Update Stream

    private var flagUpdateContinuation: AsyncStream<FlagUpdate>.Continuation?
    public let flagUpdateStream: AsyncStream<FlagUpdate>

    // MARK: - Initialization

    public init() {
        var continuation: AsyncStream<FlagUpdate>.Continuation?
        self.flagUpdateStream = AsyncStream { continuation = $0 }
        self.flagUpdateContinuation = continuation
    }

    // MARK: - ExperimentationClientProtocol

    public func initialize() async throws {
        initializeCalled = true
    }

    public func refresh() async throws {
        refreshCalled = true
    }

    public func handleUserStateChange(_ state: ExperimentationUserState) async throws {
        lastUserState = state
    }

    public func boolValue(forKey key: String, defaultValue: Bool) async -> Bool {
        boolValues[key] ?? defaultValue
    }

    public func stringValue(forKey key: String, defaultValue: String) async -> String {
        stringValues[key] ?? defaultValue
    }

    public func doubleValue(forKey key: String, defaultValue: Double) async -> Double {
        doubleValues[key] ?? defaultValue
    }

    public func jsonData(forKey key: String) async -> Data? {
        jsonDataValues[key]
    }

    // MARK: - Test Helpers

    /// Simulates a flag update from LaunchDarkly.
    ///
    /// Use this in tests to verify that the facade correctly handles real-time updates.
    public func simulateFlagUpdate(key: String) {
        flagUpdateContinuation?.yield(FlagUpdate(key: key))
    }

    /// Simulates multiple flag updates.
    public func simulateFlagUpdates(keys: [String]) {
        for key in keys {
            simulateFlagUpdate(key: key)
        }
    }
}
