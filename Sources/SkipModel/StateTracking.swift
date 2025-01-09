// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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

/// Manage observable state tracking.
public final class StateTracking {
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
