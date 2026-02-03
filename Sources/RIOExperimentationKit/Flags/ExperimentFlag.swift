//
//  ExperimentFlag.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - ExperimentFlag Protocol

/// A type-safe representation of a feature flag.
///
/// `ExperimentFlag` provides compile-time type safety for feature flags. Instead of using
/// string keys and hoping you call the right method, each flag type enforces its value type
/// at compile time.
///
/// ## Available Flag Types
/// - `BoolFlag`: For on/off toggles
/// - `StringFlag`: For raw string values
/// - `DoubleFlag`: For numeric values
/// - `JSONFlag<T>`: For complex configuration objects (decoded to your type)
/// - `VariationFlag`: For A/B test variations (control/variant/custom)
///
/// ## Defining Flags
/// Define all your flags in a `Flags` enum:
/// ```swift
/// enum Flags {
///     static let newFeature = BoolFlag("newFeature")
///     static let apiTimeout = DoubleFlag("apiTimeout", default: 30.0)
///     static let homeConfig = JSONFlag<HomeConfig>("homeConfig")
/// }
/// ```
///
/// ## Using Flags
/// ```swift
/// // The compiler enforces the correct return type
/// let enabled: Bool = facade.value(for: Flags.newFeature)
/// let timeout: Double = facade.value(for: Flags.apiTimeout)
/// let config: HomeConfig? = facade.value(for: Flags.homeConfig)
/// ```
///
/// ## Flag Lifecycle
/// Feature flags are temporary by design. Once a feature is fully rolled out:
/// 1. Remove the flag from `Flags` enum
/// 2. Remove all `facade.value(for:)` calls for that flag
/// 3. Delete the flag from LaunchDarkly dashboard
///
/// This keeps the flag list small and the codebase clean.
nonisolated public protocol ExperimentFlag: Sendable {
    associatedtype Value: Sendable

    /// The key used in LaunchDarkly to identify this flag.
    var key: String { get }

    /// The default value to return if the flag cannot be fetched or hasn't loaded yet.
    var defaultValue: Value { get }

    /// Controls when updates to this flag take effect.
    var updatePolicy: UpdatePolicy { get }
}


// MARK: - BoolFlag

/// A boolean feature flag for on/off toggles.
///
/// Use `BoolFlag` for simple feature gates:
/// ```swift
/// static let darkMode = BoolFlag("darkMode", default: false)
///
/// if facade.value(for: Flags.darkMode) {
///     applyDarkTheme()
/// }
/// ```
nonisolated public struct BoolFlag: ExperimentFlag {
    public let key: String
    public let defaultValue: Bool
    public let updatePolicy: UpdatePolicy

    public init(_ key: String, default defaultValue: Bool = false, policy: UpdatePolicy = .deferred) {
        self.key = key
        self.defaultValue = defaultValue
        self.updatePolicy = policy
    }
}


// MARK: - StringFlag

/// A string feature flag for raw string values.
///
/// Use `StringFlag` when you need the raw string value. For A/B test variations,
/// consider using `VariationFlag` instead for better semantics.
///
/// ```swift
/// static let welcomeMessage = StringFlag("welcomeMessage", default: "Welcome!")
///
/// let message = facade.value(for: Flags.welcomeMessage)
/// ```
nonisolated public struct StringFlag: ExperimentFlag {
    public let key: String
    public let defaultValue: String
    public let updatePolicy: UpdatePolicy

    public init(_ key: String, default defaultValue: String = "", policy: UpdatePolicy = .deferred) {
        self.key = key
        self.defaultValue = defaultValue
        self.updatePolicy = policy
    }
}


// MARK: - DoubleFlag

/// A numeric feature flag for decimal values.
///
/// Use `DoubleFlag` for numeric configuration:
/// ```swift
/// static let scrollThreshold = DoubleFlag("scrollThreshold", default: 0.5)
/// static let apiTimeout = DoubleFlag("apiTimeout", default: 30.0, policy: .immediate)
///
/// let threshold = facade.value(for: Flags.scrollThreshold)
/// ```
nonisolated public struct DoubleFlag: ExperimentFlag {
    public let key: String
    public let defaultValue: Double
    public let updatePolicy: UpdatePolicy

    public init(_ key: String, default defaultValue: Double = 0.0, policy: UpdatePolicy = .deferred) {
        self.key = key
        self.defaultValue = defaultValue
        self.updatePolicy = policy
    }
}


// MARK: - JSONFlag

/// A JSON feature flag that decodes to a typed model.
///
/// Use `JSONFlag<T>` for complex configuration objects:
/// ```swift
/// struct HomeConfig: Codable, Sendable {
///     let showBanner: Bool
///     let bannerText: String
///     let maxItems: Int
/// }
///
/// static let homeConfig = JSONFlag<HomeConfig>("homeConfig")
///
/// if let config = facade.value(for: Flags.homeConfig) {
///     configurePage(with: config)
/// }
/// ```
///
/// - Note: Returns `nil` if the flag is not found or fails to decode.
///   Use the `default` parameter to provide a fallback value.
nonisolated public struct JSONFlag<T: Codable & Sendable>: ExperimentFlag {
    public let key: String
    public let defaultValue: T?
    public let updatePolicy: UpdatePolicy

    public init(_ key: String, default defaultValue: T? = nil, policy: UpdatePolicy = .deferred) {
        self.key = key
        self.defaultValue = defaultValue
        self.updatePolicy = policy
    }
}


// MARK: - VariationFlag

/// A variation feature flag for A/B test experiments.
///
/// Use `VariationFlag` when running A/B tests with string-based variations:
/// ```swift
/// static let checkoutExperiment = VariationFlag("checkoutExperiment")
///
/// switch facade.value(for: Flags.checkoutExperiment) {
/// case .control:
///     showOriginalCheckout()
/// case .variant:
///     showNewCheckout()
/// case .nthVariant(let name):
///     showCustomVariant(name)
/// }
/// ```
nonisolated public struct VariationFlag: ExperimentFlag {

    public let key: String
    public let defaultValue: VariationResult
    public let updatePolicy: UpdatePolicy

    public init(_ key: String, default defaultValue: VariationResult = .control, policy: UpdatePolicy = .deferred) {
        self.key = key
        self.defaultValue = defaultValue
        self.updatePolicy = policy
    }
}
