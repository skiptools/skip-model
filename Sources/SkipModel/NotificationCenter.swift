// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP

import Foundation

extension NotificationCenter {
    public func publisher(for name: Notification.Name, object: AnyObject? = nil) -> Publisher<Notification, Never> {
        let publisher = NotificationCenterPublisher(center: self)
        publisher.observer = addObserver(forName: name, object: object, queue: nil) {
            publisher.send($0)
        }
        return publisher
    }
}

private final class NotificationCenterPublisher: Publisher {
    typealias Output = Notification
    typealias Failure = Never

    private let center: NotificationCenter
    private let helper: SubjectHelper<Notification, Never> = SubjectHelper<Notification, Never>()
    var observer: Any?

    init(center: NotificationCenter) {
        self.center = center
    }

    deinit {
        if let observer {
            center.removeObserver(observer)
        }
    }

    func sink(receiveValue: (Notification) -> Void) -> AnyCancellable {
        let internalCancellable = helper.sink(receiveValue)
        let referencingCancellable = ReferencingCancellable(publisher: self, cancellable: internalCancellable)
        return AnyCancellable(referencingCancellable)
    }

    func send(notification: Notification) {
        helper.send(notification)
    }
}

/// Cancellable that references the producing publisher.
///
/// The publisher will deregister from the notification center only when it finalizes after all these references are gone.
private final class ReferencingCancellable: Cancellable {
    private var publisher: NotificationCenterPublisher?
    private let cancellable: Cancellable

    init(publisher: NotificationCenterPublisher?, cancellable: Cancellable) {
        self.publisher = publisher
        self.cancellable = cancellable
    }

    func cancel() {
        publisher = nil
        cancellable.cancel()
    }
}

#endif
