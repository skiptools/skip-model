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

    public func combineLatest<P>(_ publisher: Publisher<P, Failure>) -> Publisher<(Output, P), Failure> {
        fatalError()
    }

    public func combineLatest3<P0, P1>(_ publisher0: Publisher<P0, Failure>, _ publisher1: Publisher<P1, Failure>) -> Publisher<(Output, P0, P1), Failure> {
        fatalError()
    }

    public func combineLatest4<P0, P1, P2>(_ publisher0: Publisher<P0, Failure>, _ publisher1: Publisher<P1, Failure>, _ publisher2: Publisher<P2, Failure>) -> Publisher<(Output, P0, P1, P2), Failure> {
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

    public func eraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        fatalError()
    }
}

public final class AnyPublisher : Publisher {
    public init(_ publisher: Publisher<Output, Failure>) {
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
