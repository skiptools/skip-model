// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP

public protocol Cancellable {
    func cancel()
}

public final class AnyCancellable : Cancellable, Hashable {
    var cancellable: Cancellable?

    init() {
    }

    public init(_ cancellable: Cancellable) {
        self.init()
        self.cancellable = cancellable
    }

    public init(_ cancel: @escaping () -> Void) {
        self.init(CancelClosure(onCancel: cancel))
    }

    public func cancel() {
        if let cancellable {
            cancellable.cancel()
        }
    }

    public func store(in set: inout Set<AnyCancellable>) {
        set.insert(self)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cancellable)
    }

    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        return lhs.cancellable == rhs.cancellable
    }

    struct CancelClosure : Cancellable {
        let onCancel: () -> Void

        func cancel() {
            onCancel()
        }
    }
}

#endif
