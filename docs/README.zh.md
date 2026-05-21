# SwiftAttach 🚀

> [English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

`SwiftAttach` 是一个轻量级依赖注入（DI）框架，通过 **Swift Macros** 在编译时提供类型安全和声明式的依赖注入。

---

## 安装

### Swift Package Manager

在 Xcode 中选择 `File > Add Package Dependencies...`，然后输入以下 URL：

```
https://github.com/lips9943/swift-attach.git
```

或在 `Package.swift` 中直接添加：

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

## 环境要求

- **Swift** 6.2+
- **Platforms**: macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+

---

## 快速开始

### 1. 定义协议和实现

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

### 2. 编写配置类

```swift
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        RepositoryImpl()
    }
}
```

### 3. 初始化应用

```swift
// 在应用启动时执行一次
DIConfig()
```

### 4. 使用依赖

```swift
@Service
class ServiceImpl: Service {
    var repo: Repository! // RepositoryImpl 会自动注入
}
```

---

## 宏

### `@Service`

声明在需要依赖注入的类或结构体上。自动分析内部变量，应用 `@PropertyInjection`，并生成从容器获取实例的私有属性。

### `@AttachConfig`

声明在将对象注册到 DI 容器的配置类上。分析内部方法，自动生成将对象注册到容器的 `init()`。

### `@PropertyInjection`

附加到变量声明上，将实际的 getter 连接到私有宏扩展属性。注入目标变量必须是可选（`?`）或隐式解包可选（`!`）类型。

### 标记宏

| 标记 | 说明 |
|------|------|
| `@Singleton` | 以单例（`.shared` 作用域）注入依赖 |
| `@NonImplement` | 对不符合标准 `[Type]Impl` 命名规范的类型，直接在容器中搜索 |
| `@Ignore` | 将特定变量从 DI 注入中排除 |

---

## Container API

### 注册 (Register)

```swift
let container = Container()

// 按类型注册
container.register(impl: RepositoryImpl())

// 按协议映射注册
container.register(protocol: Repository.self, impl: RepositoryImpl())

// 指定作用域
container.register(impl: RepositoryImpl(), scope: .shared)
```

### 解析 (Resolve)

```swift
// 按类型解析
let repo = try container.resolve(RepositoryImpl.self)

// 按协议解析
let repo = try container.resolve(RepositoryImpl.self, protocol: Repository.self)

// 可选解析（失败时返回 nil）
let repo = container.resolveOptional(RepositoryImpl.self)
```

### 注销 (Unregister)

```swift
container.unregister(type: RepositoryImpl.self, protocol: Repository.self)
container.clearAll()
```

---

## 许可证

MIT
