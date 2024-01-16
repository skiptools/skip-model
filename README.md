# SkipModel

Model object observation for [Skip](https://skip.tools) apps.

## About 

SkipModel vends the `skip.model` Kotlin package. This package contains `Observable` and `ObservableObject` interfaces, representing the two core protocols that SwiftUI uses to observe changes to model objects. It also includes limited `Publisher` support.

## Dependencies

SkipLib depends on the [skip](https://source.skip.tools/skip) transpiler plugin and the [SkipFoundation](https://source.skip.tools/skip-foundation) package.

SkipModel is part of the core *SkipStack* and is not intended to be imported directly. The transpiler includes `import skip.model.*` in generated Kotlin for any Swift source that imports the `Combine`, `Observation`, or `SwiftUI` frameworks.

## Status

From the `Observation` package, SkipModel supports the `@Observable` and `@ObservationIgnored` macros.

From `Combine`, SkipModel supports the `ObservableObject` protocol, the `@Published` property wrapper, and limited `Publisher` functionality. See [Combine support](#combine-support) below.

Much of Skip's model support is implemented directly in the Skip transpiler. The `Observable` and `ObservableObject` marker protocols are are sufficient for the Skip transpiler to recognize your observable types. When generating their corresponding Kotlin classes, the transpiler then adds the necessary code so that their state can be tracked by the Compose runtime.

## Contributing

We welcome contributions to SkipModel. The Skip product [documentation](https://skip.tools/docs/contributing/) includes helpful instructions and tips on local Skip library development. When submitting code, please include unit tests in your [PR](https://github.com/skiptools/skip-model/pulls).

## Model Objects

Like Skip itself, SkipModel objects are dual-platform! Not only do your `@Observable` and `ObservableObject` properties participate in SwiftUI state tracking, but they are tracked by Compose as well. The Skip transpiler backs your observable properties with `MutableState` values in Kotlin, so Compose automatically tracks reads and writes and [performs recomposition as needed](https://developer.android.com/jetpack/compose/state).

This means that you can write shared model-layer Swift code using observable objects, and use it to power both SwiftUI (whether iOS-only or dual-platform with Skip) as well as pure Android Compose UI code.

There is only one thing to remember: your observable objects don't activate `MutableState` property backing until you invoke the `trackstate()` function. This is a special function that Skip adds to the Android version of your observable types:

```kotlin
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
```

Skip automatically calls `trackstate()` on your objects when you use them in shared SwiftUI code. But you have to call it yourself when using them with your own Compose. So if you defined the following type in your shared Swift code:

```swift
@Observable class TapCounter {
    var tapCount = 0 
}
```

Then you could use it in your Compose code like so:

```kotlin
val tapCounter = TapCounter()
tapCounter.trackstate()
...
TapIt(counter = tapCounter)
...
@Composable fun TapIt(counter: TapCounter) {
    Button(onClick = { counter.tapCount += 1 }) { 
        Text("Tap Count: ${counter.tapCount}")
    }
}
```

## Combine Support

SkipModel supports the following Combine types and operations. Note that in all cases the `Failure` type must be `Never`: throwing errors in Combine chains is not supported.

|Component|Notes|
|---------|-----|
|`AnyCancellable`||
|`Cancellable`||
|`ObservableObject`||
|`PassthroughSubject`||
|`@Published`||
|`Publisher`||
|`Subject`||
|`.debounce(for:scheduler:)`|Only seconds as `Double` and `RunLoop.main`/`DispatchQueue.main` supported|
|`.dropFirst`||
|`.filter`||
|`.map`||
|`.receive(on:)`|Only `RunLoop.main`/`DispatchQueue.main` supported|
|`.store(in:)` (AnyCancellable)|Must store in a `Set`|

