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
    private static let contexts: MutableList<MutableList<StateTracker>> = mutableListOf()
    #endif

    /// Register a state tracker to call when state tracking should begin.
    ///
    /// If there is a current context, delays state tracking until the context is popped so that creating
    /// and updating an observable in the same context does not result in a potential infinite loop:
    ///
    /// - Parent view `P` creates child view `V`
    /// - On construction, `V` creates observable `@StateObject` `O`
    /// - Either `O` or `V` both read and update one of `O`'s observable properties in their constructors
    ///
    /// If `O`'s properites were immediately backed by `MutableState`, that sequence would cause the state
    /// to be both read and updated in the context of `P`, causing `P` to recompose and recreate `V`, which
    /// would recreate `O` and cause the cycle to repeat.
    public static func register(_ tracker: StateTracker) {
        #if SKIP
        if isMainThread, let context = contexts.lastOrNull() {
            context.add(tracker)
        } else {
            tracker.trackState()
        }
        #else
        tracker.trackState()
        #endif
    }

    /// Push an observation context.
    public static func pushContext() {
        #if SKIP
        if isMainThread {
            contexts.add(mutableListOf<StateTracker>())
        }
        #endif
    }

    /// Pop the current observation context.
    public static func popContext() {
        #if SKIP
        guard isMainThread, let context = contexts.removeLastOrNull() else {
            return
        }
        for tracker in context {
            tracker.trackState()
        }
        #endif
    }

    #if SKIP
    private static var isMainThread: Bool {
        // Looper not mocked for Roboelectric and will cause test exceptions, so use `try`
        return try? (Looper.myLooper() == Looper.getMainLooper()) ?? false
    }
    #endif
}
