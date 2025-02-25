// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
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
                return projectedValue.value
            } else {
                return _wrappedValue
            }
        }
        set {
            if let projectedValue {
                projectedValue.value = newValue
            }
            _wrappedValue = newValue
        }
    }
    private var _wrappedValue: Value

    public var projectedValue: MutableState<Value>?

    public func trackState() {
        // Once we create our internal MutableState, reads and writes will be tracked by Compose
        if projectedValue == nil {
            projectedValue = mutableStateOf(_wrappedValue)
        }
    }
}

#endif

