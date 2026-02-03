//
//  ExperimentationFacade.swift
//  RIOExperimentationKit
//
//  Created by Christopher J. Roura on 1/28/26.
//

import Foundation
import Observation

// MARK: - ExperimentationFacade

@Observable
public final class ExperimentationFacade {

    // MARK: - Private Properties

    private let client: ExperimentationClientProtocol
    private var activeValues: [String: FlagValue] = [:]
    private var pendingValues: [String: FlagValue] = [:]
    private var updateListenerTask: Task<Void, Never>?
    private var registeredFlags: [any ExperimentFlag] = []
    public private(set) var isInitialized = false

    // MARK: - Initialization

    public init(client: ExperimentationClientProtocol) {
        self.client = client
    }
}


// MARK: - ExperimentationManaging

extension ExperimentationFacade: ExperimentationManaging {

    public func initialize(flags: [any ExperimentFlag]) async throws {
        guard !isInitialized else { return }

        registeredFlags = flags
        try await client.initialize()
        await loadAllFlags(flags)
        startListeningForUpdates()
        isInitialized = true
    }

    public func refresh(flags: [any ExperimentFlag]) async throws {
        try await client.refresh()

        for (key, pendingValue) in pendingValues where pendingValue.policy == .deferred {
            activeValues[key] = pendingValue
        }

        pendingValues = pendingValues.filter { $0.value.policy != .deferred }
        await loadAllFlags(flags)
    }

    public func handleUserStateChange(_ state: ExperimentationUserState, flags: [any ExperimentFlag]) async throws {
        try await client.handleUserStateChange(state)
        await loadAllFlags(flags)
    }

    public func value(for flag: BoolFlag) -> Bool {
        resolveValue(forKey: flag.key, policy: flag.updatePolicy)?
            .boolValue(default: flag.defaultValue) ?? flag.defaultValue
    }

    public func value(for flag: StringFlag) -> String {
        resolveValue(forKey: flag.key, policy: flag.updatePolicy)?
            .stringValue(default: flag.defaultValue) ?? flag.defaultValue
    }

    public func value(for flag: DoubleFlag) -> Double {
        resolveValue(forKey: flag.key, policy: flag.updatePolicy)?
            .doubleValue(default: flag.defaultValue) ?? flag.defaultValue
    }

    public func value<T: Codable & Sendable>(for flag: JSONFlag<T>) -> T? {
        resolveValue(forKey: flag.key, policy: flag.updatePolicy)?
            .jsonValue(as: T.self) ?? flag.defaultValue
    }

    public func value(for flag: VariationFlag) -> VariationResult {
        resolveValue(forKey: flag.key, policy: flag.updatePolicy)?
            .variationValue(default: flag.defaultValue) ?? flag.defaultValue
    }
}


// MARK: - Factory Methods

public extension ExperimentationFacade {

    /// A mock facade for testing and SwiftUI Previews.
    ///
    /// This facade uses `MockLaunchDarklyClient` which returns default values
    /// for all flags. Use it in:
    /// - SwiftUI Previews
    /// - Unit tests
    /// - UI tests
    ///
    /// ## Example
    /// ```swift
    /// #Preview {
    ///     MyView()
    ///         .environment(\.experimentationFacade, .mock)
    /// }
    /// ```
    static var mock: ExperimentationFacade {
        ExperimentationFacade(client: MockLaunchDarklyClient())
    }

    /// Convenience method to initialize without flags.
    ///
    /// Use this when you don't need to pre-load specific flags.
    func initialize() async throws {
        try await initialize(flags: [])
    }
}


// MARK: - Private Methods

private extension ExperimentationFacade {

    func resolveValue(forKey key: String, policy: UpdatePolicy) -> FlagValue? {
        switch policy {
        case .immediate:
            return pendingValues[key] ?? activeValues[key]
        case .deferred:
            return activeValues[key]
        case .delayed:
            if let pending = pendingValues[key], pending.shouldApply() {
                activeValues[key] = pending
                pendingValues[key] = nil
                return pending
            }
            return activeValues[key]
        }
    }

    // MARK: - Load All Flags

    func loadAllFlags(_ flags: [any ExperimentFlag]) async {
        for flag in flags {
            await loadFlag(flag)
        }
    }

    func loadFlag(_ flag: any ExperimentFlag) async {
        switch flag {
        case let boolFlag as BoolFlag:
            let value = await client.boolValue(forKey: boolFlag.key, defaultValue: boolFlag.defaultValue)
            activeValues[boolFlag.key] = FlagValue(rawValue: .bool(value), receivedAt: Date(), policy: boolFlag.updatePolicy)

        case let stringFlag as StringFlag:
            let value = await client.stringValue(forKey: stringFlag.key, defaultValue: stringFlag.defaultValue)
            activeValues[stringFlag.key] = FlagValue(rawValue: .string(value), receivedAt: Date(), policy: stringFlag.updatePolicy)

        case let doubleFlag as DoubleFlag:
            let value = await client.doubleValue(forKey: doubleFlag.key, defaultValue: doubleFlag.defaultValue)
            activeValues[doubleFlag.key] = FlagValue(rawValue: .double(value), receivedAt: Date(), policy: doubleFlag.updatePolicy)

        case let variationFlag as VariationFlag:
            let value = await client.stringValue(forKey: variationFlag.key, defaultValue: "control")
            activeValues[variationFlag.key] = FlagValue(rawValue: .string(value), receivedAt: Date(), policy: variationFlag.updatePolicy)

        default:
            break
        }
    }

    // MARK: - Real-time Updates

    func startListeningForUpdates() {
        updateListenerTask = Task { [weak self] in
            guard let self else { return }
            for await update in client.flagUpdateStream {
                await self.handleFlagUpdate(update)
            }
        }
    }

    func handleFlagUpdate(_ update: FlagUpdate) async {
        guard let flag = registeredFlags.first(where: { $0.key == update.key }) else { return }

        switch flag {
        case let boolFlag as BoolFlag:
            let value = await client.boolValue(forKey: boolFlag.key, defaultValue: boolFlag.defaultValue)
            applyUpdate(key: boolFlag.key, flagValue: FlagValue(rawValue: .bool(value), receivedAt: update.receivedAt, policy: boolFlag.updatePolicy))

        case let stringFlag as StringFlag:
            let value = await client.stringValue(forKey: stringFlag.key, defaultValue: stringFlag.defaultValue)
            applyUpdate(key: stringFlag.key, flagValue: FlagValue(rawValue: .string(value), receivedAt: update.receivedAt, policy: stringFlag.updatePolicy))

        case let doubleFlag as DoubleFlag:
            let value = await client.doubleValue(forKey: doubleFlag.key, defaultValue: doubleFlag.defaultValue)
            applyUpdate(key: doubleFlag.key, flagValue: FlagValue(rawValue: .double(value), receivedAt: update.receivedAt, policy: doubleFlag.updatePolicy))

        case let variationFlag as VariationFlag:
            let value = await client.stringValue(forKey: variationFlag.key, defaultValue: "control")
            applyUpdate(key: variationFlag.key, flagValue: FlagValue(rawValue: .string(value), receivedAt: update.receivedAt, policy: variationFlag.updatePolicy))

        default:
            break
        }
    }

    func applyUpdate(key: String, flagValue: FlagValue) {
        switch flagValue.policy {
        case .immediate:
            activeValues[key] = flagValue
        case .deferred, .delayed:
            pendingValues[key] = flagValue
        }
    }
}
