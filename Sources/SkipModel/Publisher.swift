// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

// SKIP SYMBOLFILE

#if SKIP

import Foundation

public protocol Publisher<Output, Failure> {
    associatedtype Output
    associatedtype Failure
}

extension Publisher {
    public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
        fatalError()
    }

    public func assign<Root>(to keyPath: (Root, Output) -> Void, on object: Root) -> AnyCancellable {
        fatalError()
    }

    public func debounce(for dueTime: Double, scheduler: Scheduler) -> Publisher<Output, Failure> {
        fatalError()
    }

    public func dropFirst(_ count: Int = 1) -> Publisher<Output, Failure> {
        fatalError()
    }

    public func filter(_ isIncluded: (Output) throws -> Bool) rethrows -> Publisher<Output, Failure> {
        fatalError()
    }

    public func map<T>(_ transform: (Output) throws -> T) rethrows -> Publisher<T, Failure> {
        fatalError()
    }

    public func receive(on scheduler: Scheduler) -> Publisher<Output, Failure> {
        fatalError()
    }
}

public protocol ConnectablePublisher<Output, Failure> : Publisher {
    func connect() -> Cancellable
    func autoconnect() -> Publisher<Output, Failure>
}

public protocol Subject<Output, Failure> : AnyObject, Publisher {
    func send(_ value: Output)
}

public final class PassthroughSubject<Output, Failure> : Subject {
    public init() {
    }

    public func send(_ input: Output) {
    }
}

public final class ObservableObjectPublisher : Publisher {
    public typealias Output = Void
    public typealias Failure = Never

    public init() {
    }

    public func send() {
    }
}

#endif
