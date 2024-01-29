// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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

