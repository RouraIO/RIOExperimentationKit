//
//  ExperimentationManaging.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - ExperimentationManaging

/// Public protocol for the experimentation facade.
///
/// This protocol defines the public API for accessing feature flags.
/// The concrete implementation (`ExperimentationFacade`) is `@Observable`,
/// allowing SwiftUI views to automatically update when flag values change.
///
/// ## Usage
/// ```swift
/// @Environment(\.experimentationFacade) var facade
///
/// var body: some View {
///     if facade.value(for: Flags.newFeature) {
///         NewFeatureView()
///     }
/// }
/// ```
@MainActor
public protocol ExperimentationManaging {

    /// Initializes the experimentation system and loads initial flag values.
    ///
    /// Call this once at app startup, typically in your App's `init()` or
    /// in a `.task` modifier on your root view.
    ///
    /// - Parameter flags: The array of flags to load on initialization
    /// - Throws: `ExperimentationError` if initialization fails
    func initialize(flags: [any ExperimentFlag]) async throws

    /// Forces a refresh of all deferred flag values.
    ///
    /// Call this when you want to apply pending updates for `.deferred` flags.
    /// Typically called at natural transition points like:
    /// - App coming to foreground
    /// - User navigating to a new major section
    /// - Pull-to-refresh gestures
    ///
    /// - Parameter flags: The array of flags to refresh
    /// - Throws: `ExperimentationError` if refresh fails
    func refresh(flags: [any ExperimentFlag]) async throws

    /// Updates the user context when authentication state changes.
    ///
    /// Call this when:
    /// - User logs in: `.authenticated(userId: "user-123")`
    /// - User logs out: `.loggedOut`
    ///
    /// This updates the LaunchDarkly context and refreshes flag values
    /// for the new user.
    ///
    /// - Parameters:
    ///   - state: The new user authentication state
    ///   - flags: The array of flags to reload
    /// - Throws: `ExperimentationError` if the context update fails
    func handleUserStateChange(_ state: ExperimentationUserState, flags: [any ExperimentFlag]) async throws

    /// Returns the current value of a boolean flag.
    ///
    /// - Parameter flag: The flag definition
    /// - Returns: The flag value, or the default if not available
    func value(for flag: BoolFlag) -> Bool

    /// Returns the current value of a string flag.
    ///
    /// - Parameter flag: The flag definition
    /// - Returns: The flag value, or the default if not available
    func value(for flag: StringFlag) -> String

    /// Returns the current value of a double flag.
    ///
    /// - Parameter flag: The flag definition
    /// - Returns: The flag value, or the default if not available
    func value(for flag: DoubleFlag) -> Double

    /// Returns the current value of a JSON flag, decoded to the specified type.
    ///
    /// - Parameter flag: The flag definition with the expected type
    /// - Returns: The decoded value, or the default if not available or decoding fails
    func value<T: Codable & Sendable>(for flag: JSONFlag<T>) -> T?

    /// Returns the current variation result for an A/B test flag.
    ///
    /// - Parameter flag: The flag definition
    /// - Returns: The variation result, or `.control` if not available
    func value(for flag: VariationFlag) -> VariationResult
}
