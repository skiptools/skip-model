// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

/// We model `@Published` properties as Kotlin `MutableState` so that Compose will track its values.
public final class Published<Value>: StateTracker {
    private let subject: PropertySubject<Value, Never>
    private var state: MutableState<Value>?

    public init(wrappedValue: Value) {
        subject = PropertySubject(initialValue: wrappedValue)
        StateTracking.register(self)
    }

    public var wrappedValue: Value {
        get {
            if let state {
                return state.value
            } else {
                return subject.current
            }
        }
        set {
            subject.send(newValue)
            state?.value = newValue
        }
    }

    public var projectedValue: Publisher<Value, Never> {
        return subject
    }

    public func trackState() {
        // Once we create our internal MutableState, reads and writes will be tracked by Compose
        if state == nil {
            state = mutableStateOf(subject.current)
        }
    }
}

/// Property publishers immediately send the current value.
private class PropertySubject<Output, Failure> : Subject<Output, Failure> {
    private let helper: SubjectHelper<Output, Failure> = SubjectHelper<Output, Failure>()

    init(initialValue: Output) {
        self.current = initialValue
    }

    private(set) var current: Output

    override func sink(receiveValue: (Output) -> Void) -> AnyCancellable {
        let cancellable = helper.sink(receiveValue)
        if let current {
            receiveValue(current)
        }
        return cancellable
    }

    override func send(value: Output) {
        helper.send(value)
        current = value
    }
}

#endif
