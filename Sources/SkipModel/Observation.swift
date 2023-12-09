// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP

/// Kotlin representation of `Observation.Observable`.
public protocol Observable : ComposeStateTracking {
}

/// Kotlin representation of `Combine.ObservableObject`.
public protocol ObservableObject : ComposeStateTracking {
    var objectWillChange: ObservableObjectPublisher { get }
}

/// A type whose changes can be tracked by Compose.
public protocol ComposeStateTracking {
    /// Begin tracking changes to this object for Compose.
    ///
    /// The receiver will create `MutableState` backing for its observable properties on first call to this
    /// function. We delay Compose state tracking until an object is being observed in a `View` body to
    /// prevent infinite recompose when:
    ///
    /// - Parent view `P` creates child view `V`
    /// - On construction, `V` creates observable `@StateObject` `O`
    /// - Either `O` or `V` both read and update one of `O`'s observable properties in their constructors
    ///
    /// If `O`'s properites were immediately backed by `MutableState`, that sequence would cause the state
    /// to be both read and updated in the context of `P`, causing `P` to recompose and recreate `V`, which
    /// would recreate `O` and cause the cycle to repeat.
    public func trackstate()
}

#endif
