// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

public final class MutableStateBacking: StateTracker {
    private var state: MutableList<MutableState<Int>> = mutableListOf()
    // Lazily allocated: nil until the first non-nil write transaction is observed. Apps that
    // never use `withAnimation` / `withTransaction` pay zero memory per backing.
    private var lastWriteTransactions: MutableList<StateMutationTransaction?>? = nil
    private var isTracking = false

    public init() {
        StateTracking.register(self)
    }

    public func access(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            // Only consult the read cursor when this slot actually has a recorded transaction —
            // saves a ThreadLocal access on every plain state read in apps without animation.
            if let ledger = lastWriteTransactions, index < ledger.size, let tx = ledger[index] {
                StateTracking.recordRead(tx)
            }
            let _ = state[index].value
        }
    }

    public func update(stateAt index: Int) {
        synchronized(self) {
            initialize(stateAt: index)
            let tx = StateTracking.currentTransaction
            if tx != nil || lastWriteTransactions != nil {
                // Allocate the ledger lazily; once allocated, we must keep it in sync (writing
                // nil overwrites a stale tx from a prior write inside `withAnimation`).
                let ledger = ensureLedger()
                while ledger.size <= index {
                    ledger.add(nil)
                }
                ledger[index] = tx
            }
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

    private func ensureLedger() -> MutableList<StateMutationTransaction?> {
        if let existing = lastWriteTransactions {
            return existing
        }
        let created: MutableList<StateMutationTransaction?> = mutableListOf()
        lastWriteTransactions = created
        return created
    }

    public func trackState() {
        synchronized(self) {
            isTracking = true
        }
    }
}
#endif
