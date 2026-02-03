//
//  ExperimentationUserState.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - ExperimentationUserState

/// Represents the current authentication state of the user for experimentation purposes.
///
/// LaunchDarkly uses user context to determine which flags and variations to serve.
/// When the user state changes (e.g., login/logout), call `handleUserStateChange(_:)`
/// to update the context and refresh flag values.
///
/// ## Important
/// A user context is **always** created, even for anonymous users. Anonymous users
/// receive a stable anonymous ID so they get consistent experiment experiences.
///
/// ## Example
/// ```swift
/// // User logs in
/// await facade.handleUserStateChange(.authenticated(userId: "user-123"))
///
/// // User logs out
/// await facade.handleUserStateChange(.loggedOut)
/// ```
nonisolated public enum ExperimentationUserState: Equatable, Sendable {

    /// User is authenticated with a known user ID.
    /// Experiments will be consistent for this user across devices/sessions.
    case authenticated(userId: String)

    /// User has logged out. Uses the device's anonymous ID.
    /// The anonymous ID persists so the user gets consistent experiments.
    case loggedOut

    /// No user has ever logged in. Uses the device's anonymous ID.
    /// The anonymous ID persists so the user gets consistent experiments.
    case anonymous
}
