// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

public final class MutableStateBacking: StateTracker {
    private var state: MutableList<MutableState<Int>>?

    public init() {
        StateTracking.register(self)
    }

    public func access(stateAt index: Int) {
        synchronized(self) {
            if let state {
                while state.size <= index {
                    state.add(mutableStateOf(0))
                }
                let _ = state[index].value
            }
        }
    }

    public func update(stateAt index: Int) {
        synchronized(self) {
            if let state {
                while state.size <= index {
                    state.add(mutableStateOf(0))
                }
                state[index].value += 1
            }
        }
    }

    public func trackState() {
        synchronized(self) {
            if state == nil {
                state = mutableListOf()
            }
        }
    }
}
#endif
