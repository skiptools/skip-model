// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

public final class MutableStateBacking: StateTracker {
    private var state: MutableList<MutableState<Int>> = mutableListOf()
    private var lastMutationTransactions: MutableList<StateMutationTransaction?> = mutableListOf()
    private var isTracking = false

    public init() {
        StateTracking.register(self)
    }

    public func access(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            StateTracking.recordMutationRead(lastMutationTransactions[index])
            let _ = state[index].value
        }
    }

    public func update(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            lastMutationTransactions[index] = StateTracking.currentMutationTransaction
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
            lastMutationTransactions.add(nil)
        }
    }

    public func trackState() {
        synchronized(self) {
            isTracking = true
        }
    }
}
#endif
