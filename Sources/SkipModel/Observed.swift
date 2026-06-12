// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

/// We model properties of `@Observable` types as if they had this synthetic `@Observed` property wrapper.
/// Like `Published`, it uses `MutableState` to tie into Compose's observation system.
public final class Observed<Value>: StateTracker {
    public init(wrappedValue: Value) {
        _wrappedValue = wrappedValue
        StateTracking.register(self)
    }

    public var wrappedValue: Value {
        get {
            if let projectedValue {
                // Skip the recordRead call entirely when no `withAnimation` ever wrote to us —
                // the common case for non-animated state. Inside withAnimation the stamp is
                // non-nil and we report it so animatable modifiers can pick it up.
                if let tx = lastWriteTransaction {
                    StateTracking.recordRead(tx)
                }
                return projectedValue.value
            } else {
                return _wrappedValue
            }
        }
        set {
            let tx = StateTracking.currentTransaction
            // Only stamp when we have a tx to record OR we previously recorded one (so a plain
            // write clears the stale tx). Avoids a ThreadLocal hit on every plain write.
            if tx != nil || lastWriteTransaction != nil {
                lastWriteTransaction = tx
            }
            if let projectedValue {
                projectedValue.value = newValue
            }
            _wrappedValue = newValue
        }
    }
    private var _wrappedValue: Value
    private var lastWriteTransaction: StateMutationTransaction?

    public var projectedValue: MutableState<Value>?

    public func trackState() {
        // Once we create our internal MutableState, reads and writes will be tracked by Compose
        if projectedValue == nil {
            projectedValue = mutableStateOf(_wrappedValue)
        }
    }
}

#endif
