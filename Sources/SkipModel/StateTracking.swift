// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import android.os.Looper
import androidx.compose.runtime.Composable
#endif

/// Participate in observable state tracking.
///
/// This protocol is implemented by our observation property wrappers.
public protocol StateTracker {
    func trackState()
}

/// A neutral transaction marker for state mutations.
///
/// Higher-level UI packages can attach their own transaction objects here without
/// making SkipModel depend on those packages.
public protocol StateMutationTransaction: AnyObject {
}

/// Manage observable state tracking.
public final class StateTracking {
    /// The transaction currently attached to state writes.
    public static var currentMutationTransaction: StateMutationTransaction? = nil

    // Render ledger. Nil entries are meaningful: a state value written outside
    // a mutation transaction must still line up with the matching animatable.
    private static var mutationReadTransactions: [StateMutationTransaction?] = []

    #if SKIP
    private static var bodyDepth = 0
    private static let trackers: MutableList<StateTracker> = mutableListOf()
    #endif

    /// Register a state tracker to call when state tracking should begin.
    ///
    /// If a body is executing, delays state tracking until the body completes or a new body begins executing.
    /// This is meant to avoid infinite recomposition in scenarios like the following:
    ///
    /// - Parent view `P` creates child view `V`
    /// - On construction, `V` creates observable `@StateObject` `O`
    /// - Either `O` or `V` both read and update one of `O`'s observable properties in their constructors
    ///
    /// If `O`'s properites were immediately backed by `MutableState`, that sequence would cause the state
    /// to be both read and updated in the context of `P`, causing `P` to recompose and recreate `V`, which
    /// would recreate `O` and cause the cycle to repeat.
    ///
    /// We also considered tracking view construction rather than body execution. But it's possible that `P` creates
    /// and mutates `O` before passing it to `V`, or that `V` does so in a factory function, so view construction
    /// may be too limited.
    public static func register(_ tracker: StateTracker) {
        #if SKIP
        if isMainThread && bodyDepth > 0 {
            trackers.add(tracker)
        } else {
            tracker.trackState()
        }
        #else
        tracker.trackState()
        #endif
    }

    /// Push a body execution.
    public static func pushBody() {
        #if SKIP
        if isMainThread {
            if bodyDepth == 0 {
                clearMutationReads()
            }
            bodyDepth += 1
            activateTrackers()
        }
        #endif
    }

    /// Pop a body execution.
    public static func popBody() {
        #if SKIP
        if isMainThread && bodyDepth > 0 {
            bodyDepth -= 1
            activateTrackers()
        }
        #endif
    }

    /// Record the transaction that last wrote a state value as that value is read while building render state.
    public static func recordMutationRead(_ transaction: StateMutationTransaction?) {
        mutationReadTransactions.append(transaction)
    }

    /// Consume the next recorded write transaction for an animatable value.
    ///
    /// This intentionally models a render ledger, not the current write scope.
    public static func consumeMutationRead() -> StateMutationTransaction? {
        guard !mutationReadTransactions.isEmpty else {
            return nil
        }
        return mutationReadTransactions.removeFirst()
    }

    /// Clear recorded read transactions at a known lifecycle boundary.
    public static func clearMutationReads() {
        mutationReadTransactions.removeAll()
    }

    #if SKIP
    private static func activateTrackers() {
        guard !trackers.isEmpty() else {
            return
        }
        let trackersArray = trackers.toTypedArray()
        trackers.clear()
        for tracker in trackersArray {
            tracker.trackState()
        }
    }

    private static var isMainThread: Bool {
        // Looper not mocked for Robolectric and will cause test exceptions, so use `try`
        return try? (Looper.myLooper() == Looper.getMainLooper()) ?? false
    }
    #endif
}
