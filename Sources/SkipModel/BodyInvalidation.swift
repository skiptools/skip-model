// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf

// Support for native body observation tracking (SkipFuseUI). While a body is evaluated, the
// native side calls `trackBodyInvalidation()`, which subscribes the current recompose scope to a
// fresh state and returns an id. When a tracked property changes, it calls `invalidateBody(id:)`.
//
// The native side holds only the id, never a JNI reference: Observation cannot cancel a pending
// tracking, so its closures may outlive the composition by a long time. States are held weakly;
// Compose keeps one alive only while a scope still reads it, so a stale id is a no-op.

private let bodyInvalidationStates = java.util.concurrent.ConcurrentHashMap<Int, java.lang.ref.WeakReference<MutableState<Int>>>()
private let bodyInvalidationNextID = java.util.concurrent.atomic.AtomicInteger(0)

public func trackBodyInvalidation() -> Int {
    let state = mutableStateOf(0)
    let _ = state.value
    let id = bodyInvalidationNextID.incrementAndGet()
    bodyInvalidationStates.put(id, java.lang.ref.WeakReference(state))
    // Periodic O(n) sweep of collected states; use a ReferenceQueue if it shows up in profiles.
    if id % 1024 == 0 {
        bodyInvalidationStates.values.removeIf { $0.get() == nil }
    }
    return id
}

public func invalidateBody(id: Int) {
    if let state = bodyInvalidationStates.remove(id)?.get() {
        state.value += 1
    }
}
#endif
