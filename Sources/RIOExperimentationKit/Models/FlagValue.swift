//
//  FlagValue.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - FlagValue

/// Internal storage for a flag's value with metadata for update policy handling.
///
/// This struct tracks when a flag value was received from LaunchDarkly,
/// enabling the delayed update policy to determine when to apply changes.
public struct FlagValue: Sendable {

    /// The raw value from LaunchDarkly, stored as an enum for type flexibility.
    public let rawValue: RawValue

    /// When this value was received from LaunchDarkly.
    public let receivedAt: Date

    /// The update policy for this flag.
    public let policy: UpdatePolicy

    public init(rawValue: RawValue, receivedAt: Date, policy: UpdatePolicy) {
        self.rawValue = rawValue
        self.receivedAt = receivedAt
        self.policy = policy
    }

    /// Determines if this value should be applied based on its update policy.
    ///
    /// - For `.immediate`: Always returns `true`
    /// - For `.deferred`: Returns `false` (caller must check separately)
    /// - For `.delayed(seconds:)`: Returns `true` if enough time has passed
    public func shouldApply(asOf now: Date = Date()) -> Bool {
        switch policy {
        case .immediate:
            return true
        case .deferred:
            return false
        case .delayed(let seconds):
            return now.timeIntervalSince(receivedAt) >= seconds
        }
    }
}


// MARK: - RawValue

public extension FlagValue {

    /// The underlying value types supported by LaunchDarkly.
    enum RawValue: Sendable {
        case bool(Bool)
        case string(String)
        case double(Double)
        case json(Data)
    }
}


// MARK: - Extraction

public extension FlagValue {

    /// Extracts a boolean value, returning the default if the type doesn't match.
    func boolValue(default defaultValue: Bool) -> Bool {
        if case .bool(let value) = rawValue {
            return value
        }
        return defaultValue
    }

    /// Extracts a string value, returning the default if the type doesn't match.
    func stringValue(default defaultValue: String) -> String {
        if case .string(let value) = rawValue {
            return value
        }
        return defaultValue
    }

    /// Extracts a double value, returning the default if the type doesn't match.
    func doubleValue(default defaultValue: Double) -> Double {
        if case .double(let value) = rawValue {
            return value
        }
        return defaultValue
    }

    /// Extracts and decodes a JSON value to the specified type.
    func jsonValue<T: Decodable>(as type: T.Type) -> T? {
        guard case .json(let data) = rawValue else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Extracts a variation result from a string value.
    func variationValue(default defaultValue: VariationResult) -> VariationResult {
        if case .string(let value) = rawValue {
            return VariationResult.from(value)
        }
        return defaultValue
    }
}
