# SwiftAttach 🚀

> [English](README.md) | [한국어](README.ko.md) | [中文](README.zh.md)

`SwiftAttach`は、**Swift Macros**を活用してコンパイルタイムに型安全かつ宣言的な**依存性注入(Dependency Injection)**を提供する軽量DIフレームワークです。

---

## インストール

### Swift Package Manager

Xcodeで `File > Add Package Dependencies...` を選択し、以下のURLを入力してください：

```
https://github.com/lips9943/swift-attach.git
```

または `Package.swift` に直接追加：

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

## 要件

- **Swift** 6.2+
- **Platforms**: macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+

---

## クイックスタート

### 1. プロトコルと実装を定義

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

### 2. 設定クラスを書く

```swift
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        RepositoryImpl()
    }
}
```

### 3. アプリケーションを初期化

```swift
// アプリ起動時に1回だけ実行
DIConfig()
```

### 4. 依存性を使用

```swift
@Service
class ServiceImpl: Service {
    var repo: Repository! // RepositoryImplが自動的に注入される
}
```

---

## マクロ

### `@Service`

依存性注入が必要なクラスまたは構造体に宣言します。内部変数を自動的に解析し、`@PropertyInjection`を適用して、コンテナからインスタンスを取得するプライベートプロパティを生成します。

### `@AttachConfig`

DIコンテナにオブジェクトを登録する設定クラスに宣言します。内部メソッドを解析し、コンテナに自動的に登録する `init()` を生成します。

### `@PropertyInjection`

変数宣言に付加して、実際のgetterをプライベートマクロ拡張プロパティに接続します。注入対象変数はオプション(`?`)または暗黙的アンラップオプション(`!`)型である必要があります。

### マーカーマクロ

| マーカー | 説明 |
|----------|------|
| `@Singleton` | 依存性をシングルトン(`.shared`スコープ)として注入 |
| `@NonImplement` | 標準の`[Type]Impl`命名規則に従わないタイプをコンテナで直接検索 |
| `@Ignore` | 特定の変数をDI注入対象から除外 |

---

## Container API

### 登録 (Register)

```swift
let container = Container()

// タイプで登録
container.register(impl: RepositoryImpl())

// プロトコルマッピングで登録
container.register(protocol: Repository.self, impl: RepositoryImpl())

// スコープ指定
container.register(impl: RepositoryImpl(), scope: .shared)
```

### 解決 (Resolve)

```swift
// タイプで解決
let repo = try container.resolve(RepositoryImpl.self)

// プロトコルで解決
let repo = try container.resolve(RepositoryImpl.self, protocol: Repository.self)

// オプション解決（失敗時はnilを返す）
let repo = container.resolveOptional(RepositoryImpl.self)
```

### 解除 (Unregister)

```swift
container.unregister(type: RepositoryImpl.self, protocol: Repository.self)
container.clearAll()
```

---

## ライセンス

MIT
