// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import SkipModel
import XCTest

/// Direct-mode tests of the `StateTracking` machinery that backs per-slot animation
/// provenance: the per-thread transaction stack and the read cursor consumed by the
/// transformer-emitted `__animTx = StateTracking.captureLastReadAndClear()` argument at
/// every animatable modifier site.
final class TransactionTrackingTests: XCTestCase {

    func testCaptureReadReturnsNilWhenNothingRead() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let captured = StateTracking.captureRead { 42 }
        XCTAssertEqual(42, captured.value)
        XCTAssertNil(captured.transaction)
        #endif
    }

    func testRecordReadSetsCursorForCaptureRead() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "alpha")
        let captured = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(tx)
            return 1
        }
        XCTAssertEqual(1, captured.value)
        XCTAssertTrue(captured.transaction === tx)
        #endif
    }

    func testCaptureReadRestoresOuterCursorBetweenSiblings() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx1 = TestTransaction(label: "one")
        let tx2 = TestTransaction(label: "two")
        let a = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(tx1)
            return 10
        }
        let b = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(tx2)
            return 20
        }
        XCTAssertTrue(a.transaction === tx1)
        XCTAssertTrue(b.transaction === tx2)
        #endif
    }

    /// Multi-read coalescing: when several reads happen in sequence and one is nil while
    /// another is non-nil, the non-nil wins. A nil read must never clobber a previously-
    /// captured tx — matches SwiftUI's "any animated source → animate" rule.
    func testRecordReadCoalescingPreservesNonNil() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "tx")
        let captured = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(tx)
            StateTracking.recordRead(nil)
            StateTracking.recordRead(nil)
            return 1
        }
        XCTAssertTrue(captured.transaction === tx)
        #endif
    }

    func testRecordReadCoalescingFindsNonNilAfterNil() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "tx")
        let captured = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(nil)
            StateTracking.recordRead(tx)
            StateTracking.recordRead(nil)
            return 1
        }
        XCTAssertTrue(captured.transaction === tx)
        #endif
    }

    /// First non-nil wins among multiple non-nil reads (matches SwiftUI's
    /// "any animated → animate" composition rule).
    func testRecordReadCoalescingFirstNonNilWins() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let first = TestTransaction(label: "first")
        let second = TestTransaction(label: "second")
        let captured = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(first)
            StateTracking.recordRead(second)
            return 1
        }
        XCTAssertTrue(captured.transaction === first)
        #endif
    }

    /// pushBody / popBody clear the cursor at the outermost depth so a stray read from one
    /// body can't leak into the next.
    func testCursorClearedAcrossBodyBoundaries() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "tx")
        StateTracking.pushBody()
        StateTracking.recordRead(tx)
        StateTracking.popBody()
        StateTracking.pushBody()
        let captured = StateTracking.captureRead { 1 }
        StateTracking.popBody()
        XCTAssertNil(captured.transaction)
        #endif
    }

    func testNestedCaptureReadIsIsolated() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let outerTx = TestTransaction(label: "outer")
        let innerTx = TestTransaction(label: "inner")
        let outer = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(outerTx)
            let inner = StateTracking.captureRead { () -> Int in
                StateTracking.recordRead(innerTx)
                return 99
            }
            XCTAssertTrue(inner.transaction === innerTx)
            return inner.value
        }
        XCTAssertEqual(99, outer.value)
        XCTAssertTrue(outer.transaction === outerTx)
        #endif
    }

    func testPushPopTransactionStack() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        XCTAssertNil(StateTracking.currentTransaction)
        let tx1 = TestTransaction(label: "1")
        let tx2 = TestTransaction(label: "2")

        let token1 = StateTracking.pushTransaction(tx1)
        XCTAssertTrue(StateTracking.currentTransaction === tx1)

        let token2 = StateTracking.pushTransaction(tx2)
        XCTAssertTrue(StateTracking.currentTransaction === tx2)

        StateTracking.popTransaction(token2)
        XCTAssertTrue(StateTracking.currentTransaction === tx1)

        StateTracking.popTransaction(token1)
        XCTAssertNil(StateTracking.currentTransaction)
        #endif
    }

    func testClearReadCursor() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "x")
        let captured = StateTracking.captureRead { () -> Int in
            StateTracking.recordRead(tx)
            StateTracking.clearReadCursor()
            return 7
        }
        XCTAssertEqual(7, captured.value)
        XCTAssertNil(captured.transaction)
        #endif
    }

    /// `captureLastReadAndClear` is what the transformer synthesizes at each animatable
    /// modifier call site — it reads the cursor and resets it so a sibling modifier doesn't
    /// pick up the same tx.
    func testCaptureLastReadAndClearReturnsAndClears() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        let tx = TestTransaction(label: "tx")
        StateTracking.recordRead(tx)
        let first = StateTracking.captureLastReadAndClear()
        XCTAssertTrue(first === tx)
        let second = StateTracking.captureLastReadAndClear()
        XCTAssertNil(second, "second consume should see a cleared cursor")
        #endif
    }

    func testMutableStateBackingStampsTransactionOnWrite() throws {
        #if !SKIP
        throw XCTSkip("MutableStateBacking is Android-only")
        #else
        let backing = MutableStateBacking()
        backing.trackState()
        let tx = TestTransaction(label: "write-tx")

        backing.update(stateAt: 0)
        var captured = StateTracking.captureRead { () -> Int in
            backing.access(stateAt: 0)
            return 0
        }
        XCTAssertNil(captured.transaction)

        let token = StateTracking.pushTransaction(tx)
        backing.update(stateAt: 0)
        StateTracking.popTransaction(token)

        captured = StateTracking.captureRead { () -> Int in
            backing.access(stateAt: 0)
            return 0
        }
        XCTAssertTrue(captured.transaction === tx)
        #endif
    }

    func testMutableStateBackingPerSlotIsolation() throws {
        #if !SKIP
        throw XCTSkip("MutableStateBacking is Android-only")
        #else
        let backing = MutableStateBacking()
        backing.trackState()
        let txA = TestTransaction(label: "A")
        let txB = TestTransaction(label: "B")

        let tokenA = StateTracking.pushTransaction(txA)
        backing.update(stateAt: 0)
        StateTracking.popTransaction(tokenA)

        let tokenB = StateTracking.pushTransaction(txB)
        backing.update(stateAt: 1)
        StateTracking.popTransaction(tokenB)

        let r0 = StateTracking.captureRead { () -> Int in
            backing.access(stateAt: 0)
            return 0
        }
        let r1 = StateTracking.captureRead { () -> Int in
            backing.access(stateAt: 1)
            return 0
        }
        XCTAssertTrue(r0.transaction === txA)
        XCTAssertTrue(r1.transaction === txB)
        #endif
    }

    /// A write without an active transaction must clear a stale tx left by a prior
    /// in-`withAnimation` write — otherwise a subsequent read would wrongly animate.
    func testWriteOutsideTransactionClearsStaleStamp() throws {
        #if !SKIP
        throw XCTSkip("MutableStateBacking is Android-only")
        #else
        let backing = MutableStateBacking()
        backing.trackState()
        let tx = TestTransaction(label: "tx")

        let token = StateTracking.pushTransaction(tx)
        backing.update(stateAt: 0)
        StateTracking.popTransaction(token)

        backing.update(stateAt: 0)

        let captured = StateTracking.captureRead { () -> Int in
            backing.access(stateAt: 0)
            return 0
        }
        XCTAssertNil(captured.transaction, "plain write should reset the slot's stamp")
        #endif
    }

    func testCaptureReadPropagatesThrow() throws {
        #if !SKIP
        throw XCTSkip("StateTracking transaction tracking is Android-only")
        #else
        do {
            let _: CapturedRead<Int> = try StateTracking.captureRead { () throws -> Int in
                StateTracking.recordRead(TestTransaction(label: "during-throw"))
                throw TransactionTrackingTestsBoom()
            }
            XCTFail("expected throw")
        } catch is TransactionTrackingTestsBoom {
            let after = StateTracking.captureRead { 0 }
            XCTAssertNil(after.transaction)
        }
        #endif
    }
}

private struct TransactionTrackingTestsBoom: Error {}

private final class TestTransaction: StateMutationTransaction {
    let label: String
    init(label: String) { self.label = label }
}
