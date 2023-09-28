# SkipModel

Model object observation for [Skip](https://skip.tools) apps.

## About 

SkipModel vends the `skip.model` Kotlin package. This package contains `Observable` and `ObservableObject` interfaces, representing the two core protocols that SwiftUI uses to observe changes to model objects.

## Dependencies

SkipLib depends on the [skip](https://source.skip.tools/skip) transpiler plugin and the [SkipFoundation](https://source.skip.tools/skip-foundation) library.

SkipLib is part of the core Skip stack and is not intended to be imported directly. The transpiler includes `import skip.model.*` in generated Kotlin for any Swift source that imports the `Combine`, `Observation`, or `SwiftUI` frameworks.

## Status

From the `Observation` package, SkipModel supports the `@Observable` and `@ObservationIgnored` macros.

From `Combine`, SkipModel supports the `ObservableObject` protocol and `@Published` property wrapper.

Most of SkipModel's support is implemented directly in the Skip transpiler. In fact, SkipModel itself contains only empty `Observable` and `ObservableObject` marker protocols. These marker protocols are are sufficient for the Skip transpiler to recognize your observable types. When generating the corresponding Kotlin classes, the transpiler then adds the necessary code so that their state can be tracked by the Compose runtime.

Note that other than recognizing the `ObservableObject` and `@Published` markers, SkipModel does not support the Combine API.

## Contributing

We welcome contributions to SkipModel. The Skip product documentation includes helpful instructions on [local Skip library development](https://skip.tools/docs/#local-libraries). 

All forms of contributions are considered, including test cases, comments, and documentation. When submitting code, please include unit tests in your [PR](https://github.com/skiptools/skip-lib/pulls).
