//
//  UpdatePolicy.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - UpdatePolicy

/// Defines when a feature flag update takes effect after being received from LaunchDarkly.
///
/// Use update policies to control the user experience during a session:
/// - Use `.immediate` for flags where real-time updates are desirable (e.g., kill switches, maintenance mode)
/// - Use `.deferred` for flags where you want a stable experience during a user session (e.g., UI experiments)
/// - Use `.delayed(seconds:)` for a middle ground where updates apply after a buffer period
///
/// ## Example
/// ```swift
/// // Kill switch - needs to take effect immediately
/// static let maintenanceMode = BoolFlag("maintenanceMode", policy: .immediate)
///
/// // UI experiment - stable during session
/// static let newCheckoutFlow = BoolFlag("newCheckoutFlow", policy: .deferred)
///
/// // Gradual rollout - apply after 5 minutes
/// static let newHomeLayout = BoolFlag("newHomeLayout", policy: .delayed(seconds: 300))
/// ```
public enum UpdatePolicy: Equatable, Sendable {

    /// Flag updates take effect immediately when received from LaunchDarkly.
    /// Use for critical flags like kill switches or maintenance mode.
    case immediate

    /// Flag updates only take effect on the next explicit `refresh()` call.
    /// Use for experiment flags where you want a stable experience during a user session.
    /// This is the recommended default for most feature flags.
    case deferred

    /// Flag updates take effect after the specified delay from when the change was received.
    /// Useful for gradual rollouts where you want some buffer before applying changes.
    case delayed(seconds: TimeInterval)
}
