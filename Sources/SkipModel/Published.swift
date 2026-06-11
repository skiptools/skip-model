// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

/// We model `@Published` properties as Kotlin `MutableState` so that Compose will track its values.
public final class Published<Value>: StateTracker {
    private let subject: PropertySubject<Value, Never>
    private var state: MutableState<Value>?
    private var lastWriteTransaction: StateMutationTransaction?

    public init(wrappedValue: Value) {
        subject = PropertySubject(initialValue: wrappedValue)
        StateTracking.register(self)
    }

    public var wrappedValue: Value {
        get {
            if let state {
                // Skip recordRead unless we actually have a tx to publish — saves a ThreadLocal
                // hit on every plain read.
                if let tx = lastWriteTransaction {
                    StateTracking.recordRead(tx)
                }
                return state.value
            } else {
                return subject.current
            }
        }
        set {
            let tx = StateTracking.currentTransaction
            if tx != nil || lastWriteTransaction != nil {
                lastWriteTransaction = tx
            }
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
