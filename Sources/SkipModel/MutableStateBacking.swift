// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

public final class MutableStateBacking: StateTracker {
    private var state: MutableList<MutableState<Int>> = mutableListOf()
    private var isTracking = false

    public init() {
        StateTracking.register(self)
    }

    public func access(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            let _ = state[index].value
        }
    }

    public func update(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            // Only update state when tracking. We do, however, read state even when tracking has not begun.
            // Otherwise post-tracking updates may not cause recomposition
            if isTracking {
                state[index].value += 1
            }
        }
    }

    private func initialize(stateAt index: Int) {
        while state.size <= index {
            state.add(mutableStateOf(0))
        }
    }

    public func trackState() {
        synchronized(self) {
            isTracking = true
        }
    }
}
#endif
