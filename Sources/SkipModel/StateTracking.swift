// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP
import android.os.Looper
import androidx.compose.runtime.Composable
#endif

/// Participate in observable state tracking.
///
/// This protocol is implemented by our observation property wrappers.
public protocol StateTracker {
    func trackState()
}

/// A neutral transaction marker for state mutations.
///
/// Higher-level UI packages (e.g. SkipUI's `Transaction`) attach their own transaction objects
/// here without making SkipModel depend on those packages. A transaction is set by an enclosing
/// scope such as `withTransaction(_:_:)` / `withAnimation(_:_:)` and is stamped onto the per-slot
/// ledger of every observed state write that occurs while the scope is active.
public protocol StateMutationTransaction: AnyObject {
}

/// Opaque token returned by `pushTransaction` so the matching `popTransaction` can restore the
/// prior transaction without exposing the stack mechanics.
public struct StateMutationTransactionToken {
    fileprivate let previous: StateMutationTransaction?
}

/// A `(value, transaction)` pair returned by `captureRead`, used by transpiler-emitted call
/// sites to carry the transaction of the most-recently-read tracked state along with the value.
public struct CapturedRead<T> {
    public let value: T
    public let transaction: StateMutationTransaction?

    public init(value: T, transaction: StateMutationTransaction?) {
        self.value = value
        self.transaction = transaction
    }
}

/// Manage observable state tracking.
public final class StateTracking {
    #if SKIP
    private static var bodyDepth = 0
    private static let trackers: MutableList<StateTracker> = mutableListOf()

    // Thread-local stack of active mutation transactions. The top of the stack is the
    // transaction stamped on state writes that happen on this thread. We allocate the inner
    // MutableList lazily so threads that never enter a `withAnimation` scope pay nothing.
    private static let transactionStack: ThreadLocal<MutableList<StateMutationTransaction>> = ThreadLocal()

    // Thread-local single-slot cursor that records the transaction of the most-recently-read
    // tracked state. Consumed by `captureLastReadAndClear` at the entry of each animatable
    // modifier implementation in SkipUI.
    private static let readCursor: ThreadLocal<StateMutationTransaction?> = ThreadLocal()
    #endif

    /// Register a state tracker to call when state tracking should begin.
    ///
    /// If a body is executing, delays state tracking until the body completes or a new body begins executing.
    /// This is meant to avoid infinite recomposition in scenarios like the following:
    ///
    /// - Parent view `P` creates child view `V`
    /// - On construction, `V` creates observable `@StateObject` `O`
    /// - Either `O` or `V` both read and update one of `O`'s observable properties in their constructors
    ///
    /// If `O`'s properites were immediately backed by `MutableState`, that sequence would cause the state
    /// to be both read and updated in the context of `P`, causing `P` to recompose and recreate `V`, which
    /// would recreate `O` and cause the cycle to repeat.
    ///
    /// We also considered tracking view construction rather than body execution. But it's possible that `P` creates
    /// and mutates `O` before passing it to `V`, or that `V` does so in a factory function, so view construction
    /// may be too limited.
    public static func register(_ tracker: StateTracker) {
        #if SKIP
        if isMainThread && bodyDepth > 0 {
            trackers.add(tracker)
        } else {
            tracker.trackState()
        }
        #else
        tracker.trackState()
        #endif
    }

    /// Push a body execution.
    public static func pushBody() {
        #if SKIP
        if isMainThread {
            // Each top-level body starts with a fresh read cursor so a stray read recorded by a
            // previous body (e.g. a value computed in `remember`) cannot be wrongly captured by an
            // animatable modifier in this body.
            if bodyDepth == 0 {
                readCursor.set(nil)
            }
            bodyDepth += 1
            activateTrackers()
        }
        #endif
    }

    /// Pop a body execution.
    public static func popBody() {
        #if SKIP
        if isMainThread && bodyDepth > 0 {
            bodyDepth -= 1
            activateTrackers()
            if bodyDepth == 0 {
                // Clear anything that leaked past the last animatable consumer so the cursor does
                // not bleed into the next composition pass.
                readCursor.set(nil)
            }
        }
        #endif
    }

    // MARK: - Transaction stack

    /// Push a transaction onto the per-thread mutation stack. Returns a token that must be passed
    /// to `popTransaction` to restore the prior transaction. Push/pop are paired by
    /// `withTransaction(_:_:)` / `withAnimation(_:_:)` implementations.
    public static func pushTransaction(_ transaction: StateMutationTransaction) -> StateMutationTransactionToken {
        #if SKIP
        let token = StateMutationTransactionToken(previous: currentTransaction)
        var stack = transactionStack.get()
        if stack == nil {
            stack = mutableListOf<StateMutationTransaction>()
            transactionStack.set(stack)
        }
        stack!.add(transaction)
        return token
        #else
        return StateMutationTransactionToken(previous: nil)
        #endif
    }

    /// Pop the topmost transaction. The `token` argument is provided for symmetry; this function
    /// strictly removes the most-recently-pushed transaction.
    public static func popTransaction(_ token: StateMutationTransactionToken) {
        #if SKIP
        guard let stack = transactionStack.get() else { return }
        if !stack.isEmpty() {
            stack.removeAt(stack.size - 1)
        }
        if stack.isEmpty() {
            transactionStack.set(nil)
        }
        #endif
    }

    /// The transaction currently active on this thread, or `nil` if no `withTransaction` scope is
    /// open. Reads the top of the per-thread transaction stack.
    public static var currentTransaction: StateMutationTransaction? {
        #if SKIP
        let stack = transactionStack.get()
        guard let stack, !stack.isEmpty() else { return nil }
        return stack[stack.size - 1]
        #else
        return nil
        #endif
    }

    // MARK: - Read cursor

    /// Record that a tracked-state read just occurred, carrying the transaction that wrote the
    /// value. Called by state-backing getters; consumed by `captureLastReadAndClear`.
    ///
    /// Semantics: when multiple reads in a row report transactions, the first non-nil one wins —
    /// matching SwiftUI's "any animated source → animate" behaviour. A read that returns `nil`
    /// (the slot was last written outside any `withTransaction` scope) must NOT clobber a
    /// previously-captured non-nil transaction; we silently drop it.
    ///
    /// Callers should usually short-circuit at their side by only invoking this when their slot
    /// actually has a non-nil ledger entry — this method already drops nils but skipping the call
    /// entirely saves a ThreadLocal access on the common no-animation read.
    public static func recordRead(_ transaction: StateMutationTransaction?) {
        #if SKIP
        guard let transaction else { return }
        if readCursor.get() == nil {
            readCursor.set(transaction)
        }
        #endif
    }

    /// Run `body` with a fresh read cursor and return both the body's result and the transaction
    /// of the most-recently-read tracked state inside it. The outer cursor is saved and restored,
    /// so nested or sequential captures cannot bleed into each other.
    ///
    /// Skipstone wraps every expression that produces an animatable value (and contains at least
    /// one potential state read) in a call to this function so the value and its provenance are
    /// paired synchronously.
    public static func captureRead<T>(_ body: () throws -> T) rethrows -> CapturedRead<T> {
        #if SKIP
        let outer = readCursor.get()
        readCursor.set(nil)
        do {
            let value = try body()
            let inner = readCursor.get()
            readCursor.set(outer)
            return CapturedRead(value: value, transaction: inner)
        } catch {
            readCursor.set(outer)
            throw error
        }
        #else
        return CapturedRead(value: try body(), transaction: nil)
        #endif
    }

    /// Clear the read cursor. Useful at known lifecycle boundaries (e.g. on entry to a body) to
    /// avoid carrying a stale read from an unrelated computation.
    public static func clearReadCursor() {
        #if SKIP
        readCursor.set(nil)
        #endif
    }

    /// Read and clear the read cursor in a single atomic operation.
    ///
    /// Synthesized by the transpiler at every animatable modifier call site as the value of the
    /// modifier's trailing `animTx:` argument. Because Kotlin evaluates function arguments
    /// left-to-right, this runs *after* the modifier's value arguments have been evaluated and so
    /// returns the transaction left behind by the most-recently-read tracked state inside them.
    /// Clearing on read prevents the cursor from leaking to a subsequent modifier in a chain.
    ///
    /// Performance: skip the `set(nil)` when the cursor is already nil — that's the dominant case
    /// for modifier sites whose args don't read any tracked state.
    public static func captureLastReadAndClear() -> StateMutationTransaction? {
        #if SKIP
        let transaction = readCursor.get()
        if transaction != nil {
            readCursor.set(nil)
        }
        return transaction
        #else
        return nil
        #endif
    }

    /// Test-only hook to wipe all per-thread state so test cases that left frames on the stack
    /// (due to early assertion failures) don't poison subsequent tests.
    public static func resetForTesting() {
        #if SKIP
        transactionStack.set(nil)
        readCursor.set(nil)
        #endif
    }

    #if SKIP
    private static func activateTrackers() {
        guard !trackers.isEmpty() else {
            return
        }
        let trackersArray = trackers.toTypedArray()
        trackers.clear()
        for tracker in trackersArray {
            tracker.trackState()
        }
    }

    private static var isMainThread: Bool {
        // Looper not mocked for Robolectric and will cause test exceptions, so use `try`
        return try? (Looper.myLooper() == Looper.getMainLooper()) ?? false
    }
    #endif
}
