// Copyright 2023–2026 Skip
#if SKIP

/// Kotlin representation of `Observation.Observable`.
public protocol Observable {
}

/// Kotlin representation of `Combine.ObservableObject`.
public protocol ObservableObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

#endif
