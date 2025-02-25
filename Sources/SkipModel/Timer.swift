// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP
import Foundation

extension Timer {
    public static func publish(every: TimeInterval, tolerance: TimeInterval? = nil, on runLoop: RunLoop, in mode: RunLoop.Mode, options: RunLoop.SchedulerOptions? = nil) -> ConnectablePublisher<Date, Never> {
        return TimerPublisher(every: every, tolerance: tolerance, on: runLoop, in: mode, options: options)
    }
}

private final class TimerPublisher: ConnectablePublisher {
    typealias Output = Date
    typealias Failure = Never

    private let helper: SubjectHelper<Date, Never> = SubjectHelper<Date, Never>()
    private let timeInterval: TimeInterval
    private let runLoop: RunLoop
    private let mode: RunLoop.Mode
    private var timer: Timer?
    private var connections = 0

    init(every: TimeInterval, tolerance: TimeInterval?, on runLoop: RunLoop, in mode: RunLoop.Mode, options: RunLoop.SchedulerOptions?) {
        self.timeInterval = every
        self.runLoop = runLoop
        self.mode = mode
    }

    deinit {
        timer?.invalidate()
    }

    func connect() -> Cancellable {
        let lock = self
        synchronized(lock) {
            connections += 1
            if connections == 1 {
                timer = Timer(timeInterval: timeInterval, repeats: true) {
                    helper.send(Date())
                }
                runLoop.add(timer!, forMode: mode)
            }
        }
        return AnyCancellable {
            synchronized(lock) {
                connections -= 1
                if connections <= 0 {
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
    }

    func sink(receiveValue: (Date) -> Void) -> AnyCancellable {
        return helper.sink(receiveValue)
    }
}
#endif
