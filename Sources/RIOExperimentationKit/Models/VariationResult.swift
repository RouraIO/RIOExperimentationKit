//
//  VariationResult.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation

// MARK: - VariationResult

/// Represents the result of a string-based A/B test variation.
///
/// Use `VariationResult` when you have string-based experiments where users are bucketed
/// into different treatment groups. LaunchDarkly returns strings like "control", "variant",
/// or custom variation names.
///
/// ## Example
/// ```swift
/// switch facade.value(for: Flags.checkoutExperiment) {
/// case .control:
///     showOriginalCheckout()
/// case .variant:
///     showNewCheckout()
/// case .nthVariant(let name):
///     // Handle custom variations like "variantB", "variantC", etc.
///     showCustomCheckout(name)
/// }
/// ```
public enum VariationResult: Equatable, Sendable {

    /// The control group - users see the original/default experience.
    case control

    /// The primary variant group - users see the new/test experience.
    case variant

    /// A named variant for multi-variant experiments.
    /// The associated string contains the variation name from LaunchDarkly.
    case nthVariant(String)
}


// MARK: - Factory

public extension VariationResult {

    /// Creates a `VariationResult` from a raw string value returned by LaunchDarkly.
    ///
    /// - Parameter string: The raw variation string from LaunchDarkly
    /// - Returns: The appropriate `VariationResult` case
    static func from(_ string: String) -> VariationResult {
        let lowercased = string.lowercased()
        if lowercased == "control" || lowercased.isEmpty {
            return .control
        } else if lowercased == "variant" {
            return .variant
        } else {
            return .nthVariant(string)
        }
    }
}
