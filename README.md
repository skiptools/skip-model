# SkipModel

Model object observation for [Skip](https://skip.tools) apps.

## About 

SkipModel vends the `skip.model` Kotlin package. This package contains `Observable` and `ObservableObject` interfaces, representing the two core protocols that SwiftUI uses to observe changes to model objects.

## Dependencies

SkipLib depends on the [skip](https://source.skip.tools/skip) transpiler plugin and the [SkipLib](https://source.skip.tools/skip-lib) package.

SkipModel is part of the core *SkipStack* and is not intended to be imported directly. The transpiler includes `import skip.model.*` in generated Kotlin for any Swift source that imports the `Combine`, `Observation`, or `SwiftUI` frameworks.

## Status

From the `Observation` package, SkipModel supports the `@Observable` and `@ObservationIgnored` macros.

From `Combine`, SkipModel supports the `ObservableObject` protocol and `@Published` property wrapper.

Most of Skip's model support is implemented directly in the Skip transpiler. In fact, SkipModel itself contains only empty `Observable` and `ObservableObject` marker protocols. These marker protocols are are sufficient for the Skip transpiler to recognize your observable types. When generating their corresponding Kotlin classes, the transpiler then adds the necessary code so that their state can be tracked by the Compose runtime.

Note that other than recognizing the `ObservableObject` and `@Published` markers, SkipModel does not support the Combine API.

## Contributing

We welcome contributions to SkipModel. The Skip product [documentation](https://skip.tools/docs/contributing/) includes helpful instructions and tips on local Skip library development. 

There are no immediate plans to support additional Combine or Observation module API, but all forms of contributions are considered. That includes test cases, comments, and documentation. When submitting code, please include unit tests in your [PR](https://github.com/skiptools/skip-model/pulls).

