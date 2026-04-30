// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import SkipModel
import XCTest

final class StateTrackingTests: XCTestCase {
    func testMutationReadTransactionsAreConsumedInReadOrder() {
        let first = TestStateMutationTransaction()
        let second = TestStateMutationTransaction()

        StateTracking.clearMutationReads()
        StateTracking.recordMutationRead(nil)
        StateTracking.recordMutationRead(first)
        StateTracking.recordMutationRead(second)

        XCTAssertNil(StateTracking.consumeMutationRead())
        XCTAssertTrue(StateTracking.consumeMutationRead() === first)
        XCTAssertTrue(StateTracking.consumeMutationRead() === second)
        XCTAssertNil(StateTracking.consumeMutationRead())

        StateTracking.clearMutationReads()
    }
}

private final class TestStateMutationTransaction: StateMutationTransaction {
}
