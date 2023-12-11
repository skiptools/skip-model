// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP

/// We model `@Published` properties as Kotlin `MutableState`, so this type only exists to vend
/// the property `Publisher`. We actually vend a `Subject` so we can send values from `willSet`.
public final class Published<Value> {
    public let projectedValue: Subject<Value, Never> = PropertySubject<Value, Never>()

    public init() {
    }

    public init(initialValue: Value) {
        projectedValue.send(initialValue)
    }
}

/// Property publishers immediately send the current value.
private class PropertySubject<Output, Failure> : Subject<Output, Failure> {
    private let helper: SubjectHelper<Output, Failure> = SubjectHelper<Output, Failure>()
    private var current: Output?

    override func sink(receiveValue: (Output) -> Void) -> AnyCancellable {
        let cancellable = helper.sink(receiveValue)
        if let current {
            receiveValue(current)
        }
        return cancellable
    }

    override func send(value: Output) {
        current = value
        helper.send(value)
    }
}

#endif
