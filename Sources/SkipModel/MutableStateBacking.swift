// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

public final class MutableStateBacking: StateTracker {
    private let stateCount: Int
    private var state: List<MutableState<Int>>?

    public init(stateCount: Int) {
        self.stateCount = stateCount
        StateTracking.register(self)
    }

    public func access(stateAt index: Int) {
        let _ = state?[index].value
    }

    public func update(stateAt index: Int) {
        state?[index].value += 1
    }

    public func trackState() {
        if state == nil {
            state = List(stateCount) { _ in mutableStateOf(0) }
        }
    }
}
#endif
