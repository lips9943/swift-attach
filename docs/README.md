# SwiftAttach 🚀

> [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

`SwiftAttach` is a lightweight Dependency Injection (DI) framework that provides type-safe, declarative DI through **Swift Macros** at compile time.

Define dependency relationships with annotation-based syntax and build a safe, flexible DI system without boilerplate code via compile-time code generation.

---

## Installation

### Swift Package Manager

In Xcode, go to `File > Add Package Dependencies...` and enter the following URL:

```
https://github.com/lips9943/swift-attach.git
```

Or add it directly to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/lips9943/swift-attach.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SwiftAttach", package: "swift-attach")
        ]
    ),
]
```

---

## Requirements

- **Swift** 6.2+
- **Platforms**: macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+

---

## Quick Start

### 1. Define Protocol and Implementation

```swift
import SwiftAttach

protocol Repository {
    var text: String { get }
}

@Service
class RepositoryImpl: Repository {
    var text: String { "Hello, SwiftAttach!" }
}
```

### 2. Write Configuration Class

```swift
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        RepositoryImpl()
    }
}
```

### 3. Initialize Application

```swift
// Run once at app launch
DIConfig()
```

### 4. Use Dependencies

```swift
@Service
class ServiceImpl: Service {
    var repo: Repository! // RepositoryImpl is injected automatically
}
```

---

## Macros

### `@Service`

Declare on classes or structs that need dependency injection. It automatically analyzes internal variables, applies `@PropertyInjection`, and generates private properties to fetch instances from the container.

### `@AttachConfig`

Declare on configuration classes that register objects with the DI container. It analyzes internal methods and automatically generates an `init()` that registers them with the container.

### `@PropertyInjection`

Attaches to variable declarations to connect the actual getter to a private macro-expanded property. The injection target must be an optional (`?`) or implicitly unwrapped optional (`!`) type.

### Marker Macros

| Marker | Description |
|--------|-------------|
| `@Singleton` | Inject the dependency as a singleton (`.shared` scope) |
| `@NonImplement` | Search the container directly for types that don't follow the `[Type]Impl` naming convention |
| `@Ignore` | Exclude a specific variable from DI injection |

---

## Container API

### Register

```swift
let container = Container()

// Register by type
container.register(impl: RepositoryImpl())

// Register with protocol mapping
container.register(protocol: Repository.self, impl: RepositoryImpl())

// With scope
container.register(impl: RepositoryImpl(), scope: .shared)
```

### Resolve

```swift
// Resolve by type
let repo = try container.resolve(RepositoryImpl.self)

// Resolve by protocol
let repo = try container.resolve(RepositoryImpl.self, protocol: Repository.self)

// Optional resolve (returns nil on failure)
let repo = container.resolveOptional(RepositoryImpl.self)
```

### Unregister

```swift
container.unregister(type: RepositoryImpl.self, protocol: Repository.self)
container.clearAll()
```

---

## License

MIT
