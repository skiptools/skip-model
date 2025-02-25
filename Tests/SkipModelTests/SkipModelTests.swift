// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Combine
import Foundation
import XCTest

@available(macOS 13, macCatalyst 16, iOS 16, tvOS 16, watchOS 8, *)
final class SkipModelTests: XCTestCase {
    var published = -1

    func testObjectWillChange() {
        let model = Model()
        var observed = -1
        let cancellable = model.objectWillChange.sink {
            observed = model.value
        }
        XCTAssertEqual(observed, -1)
        model.value = 5
        XCTAssertEqual(observed, 0)
        model.value = 100
        XCTAssertEqual(observed, 5)
        XCTAssertEqual(model.value, 100)

        cancellable.cancel()
        model.value = 200
        XCTAssertEqual(observed, 5)
        XCTAssertEqual(model.value, 200)
    }

    func testPropertyPublisher() {
        let model = Model()
        var published = -1
        var observed = -1
        let cancellable = model.$value.sink {
            published = $0
            observed = model.value
        }
        XCTAssertEqual(published, 0)
        XCTAssertEqual(observed, 0)
        model.value = 5
        XCTAssertEqual(published, 5)
        XCTAssertEqual(observed, 0)
        model.value = 100
        XCTAssertEqual(published, 100)
        XCTAssertEqual(observed, 5)
        XCTAssertEqual(model.value, 100)

        cancellable.cancel()
        model.value = 200
        XCTAssertEqual(published, 100)
        XCTAssertEqual(observed, 5)
        XCTAssertEqual(model.value, 200)
    }

    func testAssignTo() {
        let model = Model()
        published = -1
        let cancellable = model.$value.assign(to: \.published, on: self)
        XCTAssertEqual(published, 0)
        model.value = 5
        XCTAssertEqual(published, 5)
        model.value = 100
        XCTAssertEqual(published, 100)
        XCTAssertEqual(model.value, 100)

        cancellable.cancel()
        model.value = 200
        XCTAssertEqual(published, 100)
    }

    func testPassthroughSubject() {
        let subject = PassthroughSubject<Int, Never>()
        subject.send(1)
        subject.send(2)
        subject.send(3)

        var published = -1
        let cancellable = subject.sink {
            published = $0
        }
        XCTAssertEqual(published, -1)

        subject.send(4)
        XCTAssertEqual(published, 4)

        cancellable.cancel()
        subject.send(5)
        XCTAssertEqual(published, 4)
    }

    func testEraseToAnyPublisher() {
        let subject = PassthroughSubject<Int, Never>()
        let publisher: AnyPublisher<Int, Never> = subject.eraseToAnyPublisher()

        var published = -1
        let cancellable = publisher.sink {
            published = $0
        }

        subject.send(4)
        XCTAssertEqual(published, 4)
        cancellable.cancel()
    }

    func testMap() {
        let model = Model()
        var published = ""
        let cancellable = model.$value.map {
            String(describing: $0)
        }.sink {
            published = $0
        }
        XCTAssertEqual(published, "0")
        model.value = 5
        XCTAssertEqual(published, "5")

        cancellable.cancel()
        model.value = 100
        XCTAssertEqual(published, "5")
    }

    func testCombineLatest() {
        let model = Model()
        var published = (-1, "-")
        let cancellable = model.$value.combineLatest(model.$value2)
            .sink {
                published = $0
            }
        XCTAssertEqual(published.0, 0)
        XCTAssertEqual(published.1, "")
        model.value = 5
        XCTAssertEqual(published.0, 5)
        XCTAssertEqual(published.1, "")
        model.value2 = "a"
        XCTAssertEqual(published.0, 5)
        XCTAssertEqual(published.1, "a")

        cancellable.cancel()
    }

    func testStoreIn() {
        let model = Model()
        var cancellables: Set<AnyCancellable> = []
        model.$value.sink { _ in  }.store(in: &cancellables)
        XCTAssertEqual(cancellables.count, 1)
    }

    func testNotificationCenter() {
        var published = 0
        let cancellable = NotificationCenter.default.publisher(for: .testNotification)
            .sink {
                XCTAssertEqual($0.name, Notification.Name.testNotification)
                published += 1
            }
        XCTAssertEqual(published, 0)
        NotificationCenter.default.post(name: .testNotification, object: nil)
        XCTAssertEqual(published, 1)
        NotificationCenter.default.post(name: .testNotification, object: nil)
        XCTAssertEqual(published, 2)
        cancellable.cancel()
        NotificationCenter.default.post(name: .testNotification, object: nil)
        XCTAssertEqual(published, 2)
    }
}

class Model: ObservableObject {
    @Published var value = 0
    @Published var value2 = ""
}

extension Notification.Name {
    static var testNotification: Notification.Name {
        return Notification.Name("test")
    }
}
