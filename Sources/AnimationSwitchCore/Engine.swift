/// What one operation did to one animation.
public enum OutcomeResult: Hashable, Sendable {
    /// The disabled value was written.
    case applied
    /// The Original Value was put back.
    case restored
    /// Nothing needed to change.
    case unchanged
    /// The change didn't happen, with a one-line reason for the inline warning.
    case failed(String)
}

public struct AnimationOutcome: Hashable, Sendable {
    public let id: AnimationID
    public let result: OutcomeResult
    /// Inline notes to show under the toggle right now.
    public let notes: [AnimationNote]
}

/// The result of one engine operation: an outcome for every catalog animation,
/// in catalog order, plus problems that belong to no single animation.
public struct Report: Hashable, Sendable {
    public let outcomes: [AnimationOutcome]
    public let warnings: [String]

    public subscript(id: AnimationID) -> AnimationOutcome? {
        outcomes.first { $0.id == id }
    }
}

/// Owns the behaviour in docs/PLAN.md: disabling the Managed Animations,
/// saving and restoring Original Values, and restarting Dock and Finder once
/// per change. The menu renders the reports it returns and decides nothing.
public final class Engine {
    public let catalog: [Animation]
    public private(set) var state: AppState

    private let preferences: PreferencesStore
    private let restarter: ProcessRestarter
    private let stateStore: AppStateStore

    /// Loads the saved state, or starts from the catalog's defaults on first
    /// launch. Throws if saved state exists but can't be read, rather than
    /// starting over and losing the Original Values.
    public init(
        catalog: [Animation] = Catalog.v1,
        preferences: PreferencesStore,
        restarter: ProcessRestarter,
        stateStore: AppStateStore
    ) throws {
        self.catalog = catalog
        self.preferences = preferences
        self.restarter = restarter
        self.stateStore = stateStore
        self.state = try stateStore.load() ?? .initial(for: catalog)
    }

    /// True when the Master Switch says animations are off.
    public var animationsDisabled: Bool { state.animationsDisabled }

    public func isManaged(_ id: AnimationID) -> Bool { state.managed.contains(id) }

    /// The current notes for every animation, with nothing changed.
    public func status() -> Report {
        report([:], restartFailures: [:], warnings: [])
    }

    /// Flips the Master Switch off: disables every Managed Animation.
    public func disableAnimations() -> Report {
        var next = state
        next.animationsDisabled = true
        return disable(catalog.filter { isManaged($0.id) }, from: next)
    }

    /// Flips the Master Switch on: restores every animation the app disabled.
    public func restoreAnimations() -> Report {
        var next = state
        next.animationsDisabled = false
        return restore(catalog.filter { state.originalValues[$0.id] != nil }, from: next)
    }

    /// Checks or unchecks an Animation Toggle. While animations are on this
    /// only changes the Managed Animations. While they are off, checking
    /// disables that animation now and unchecking restores it now.
    public func setAnimationToggle(_ id: AnimationID, checked: Bool) -> Report {
        guard let animation = catalog.first(where: { $0.id == id }) else { return status() }
        var next = state
        if checked { next.managed.insert(id) } else { next.managed.remove(id) }
        guard state.animationsDisabled else {
            do {
                try stateStore.save(next)
            } catch {
                return report([id: .failed("Could not save the change: \(Self.reason(error))")],
                              restartFailures: [:], warnings: [])
            }
            state = next
            return status()
        }
        return checked ? disable([animation], from: next) : restore([animation], from: next)
    }

    /// Run once at launch. If the Master Switch says animations are off,
    /// re-applies any Managed Animation that has Drifted back, keeping its
    /// saved Original Value.
    public func reapplyDrift() -> Report {
        guard state.animationsDisabled else { return status() }
        return disable(catalog.filter { isManaged($0.id) }, from: state)
    }

    /// Restores every animation the app disabled, whatever the toggles and the
    /// Master Switch say. Used by "Restore all and quit".
    public func restoreAll() -> Report {
        restoreAnimations()
    }

    // MARK: - Disabling and restoring

    /// Disables `animations`, then makes `next` (with their Original Values
    /// added) the app's state.
    private func disable(_ animations: [Animation], from next: AppState) -> Report {
        var next = next
        var results: [AnimationID: OutcomeResult] = [:]

        // Capture Original Values the first time only, and save them before
        // writing anything, so a crash can never lose them.
        for animation in animations where next.originalValues[animation.id] == nil {
            do {
                next.originalValues[animation.id] = OriginalValue(try preferences.value(for: animation.key))
            } catch {
                results[animation.id] = .failed(Self.reason(error))
            }
        }
        do {
            try stateStore.save(next)
        } catch {
            let reason = "Could not save the original settings: \(Self.reason(error))"
            for animation in animations { results[animation.id] = .failed(reason) }
            return report(results, restartFailures: [:], warnings: [])
        }
        state = next

        var restarts: Set<RestartTarget> = []
        for animation in animations where results[animation.id] == nil {
            let result = write(animation.disabledValue, to: animation, changed: .applied)
            results[animation.id] = result
            if result == .applied, let target = animation.restart { restarts.insert(target) }
        }
        return report(results, restartFailures: restart(restarts), warnings: [])
    }

    /// Restores `animations`, then makes `next` (with their Original Values
    /// removed) the app's state.
    private func restore(_ animations: [Animation], from next: AppState) -> Report {
        var next = next
        var results: [AnimationID: OutcomeResult] = [:]
        var restarts: Set<RestartTarget> = []

        for animation in animations {
            guard let original = next.originalValues[animation.id] else { continue }
            let result = write(original.preferenceValue, to: animation, changed: .restored)
            results[animation.id] = result
            if case .failed = result { continue }
            // Forget it, so the next flip off captures any new customisation.
            next.originalValues[animation.id] = nil
            if result == .restored, let target = animation.restart { restarts.insert(target) }
        }

        var warnings: [String] = []
        do {
            try stateStore.save(next)
        } catch {
            warnings.append("Could not save the app's state: \(Self.reason(error))")
        }
        state = next
        return report(results, restartFailures: restart(restarts), warnings: warnings)
    }

    /// Writes `value` (nil deletes the key) unless the setting already has it,
    /// then reads it back to check macOS kept it.
    private func write(_ value: PreferenceValue?, to animation: Animation, changed: OutcomeResult) -> OutcomeResult {
        do {
            if Self.matches(try preferences.value(for: animation.key), value) { return .unchanged }
            if let value {
                try preferences.setValue(value, for: animation.key)
            } else {
                try preferences.removeValue(for: animation.key)
            }
            guard Self.matches(try preferences.value(for: animation.key), value) else {
                return .failed("macOS did not keep the change")
            }
            return changed
        } catch {
            return .failed(Self.reason(error))
        }
    }

    /// Restarts each target once, in a fixed order, and returns the failures.
    private func restart(_ targets: Set<RestartTarget>) -> [RestartTarget: String] {
        var failures: [RestartTarget: String] = [:]
        for target in RestartTarget.allCases where targets.contains(target) {
            do {
                try restarter.restart(target)
            } catch {
                failures[target] = Self.reason(error)
            }
        }
        return failures
    }

    // MARK: - Reports

    private func report(
        _ results: [AnimationID: OutcomeResult],
        restartFailures: [RestartTarget: String],
        warnings: [String]
    ) -> Report {
        let outcomes = catalog.map { animation in
            let result = results[animation.id] ?? .unchanged
            var notes = animation.notes
            if let condition = animation.condition, !conditionHolds(condition) {
                notes.append(condition.note)
            }
            if result == .applied || result == .restored,
                let target = animation.restart, let reason = restartFailures[target]
            {
                notes.append(.restartFailed(target, reason: reason))
            }
            return AnimationOutcome(id: animation.id, result: result, notes: notes)
        }
        return Report(outcomes: outcomes, warnings: warnings)
    }

    private func conditionHolds(_ condition: NoteCondition) -> Bool {
        do {
            guard let current = try preferences.value(for: condition.key) else { return false }
            return current.isEquivalent(to: condition.value)
        } catch {
            return true  // If the setting can't be read, don't nag about it.
        }
    }

    private static func matches(_ current: PreferenceValue?, _ wanted: PreferenceValue?) -> Bool {
        switch (current, wanted) {
        case (nil, nil): true
        case let (current?, wanted?): current.isEquivalent(to: wanted)
        default: false
        }
    }

    private static func reason(_ error: Error) -> String {
        (error as? PreferencesError)?.message ?? String(describing: error)
    }
}
