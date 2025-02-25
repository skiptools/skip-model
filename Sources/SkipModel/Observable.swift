// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP

/// Kotlin representation of `Observation.Observable`.
public protocol Observable {
}

/// Kotlin representation of `Combine.ObservableObject`.
public protocol ObservableObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

#endif
