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

