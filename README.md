# SwiftAttach 🚀

`SwiftAttach`는 **Swift Macros**를 활용하여 컴파일 타임에 타입 안전하고 선언적인 **의존성 주입(Dependency Injection)**을 제공하는 경량 DI 프레임워크입니다.

---

## Installation

### Swift Package Manager

`Xcode`에서 `File > Add Package Dependencies...` 후 다음 URL을 입력하세요:

```
https://github.com/your-username/swift-attach.git
```

또는 `Package.swift`에 직접 추가:

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

### 1. 프로토콜 및 구현체 정의

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

### 2. 설정 클래스 작성

```swift
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        RepositoryImpl()
    }
}
```

### 3. 애플리케이션 초기화

```swift
// 앱 시작 시 한 번만 실행
DIConfig()
```

### 4. 의존성 사용

```swift
@Service
class ServiceImpl: Service {
    var repo: Repository! // RepositoryImpl이 자동 주입됨
}
```

---

## Macros

### `@Service`

의존성 주입이 필요한 클래스/구조체에 선언합니다. 내부 변수를 자동으로 분석하여 `@PropertyInjection`을 부여하고, 컨테이너에서 인스턴스를 가져오는 비공개 프로퍼티를 생성합니다.

### `@AttachConfig`

DI 컨테이너에 객체를 등록하는 구성 클래스에 선언합니다. 내부 메서드를 분석하여 자동으로 컨테이너에 등록하는 `init()`을 생성합니다.

### `@PropertyInjection`

변수 선언에 부착하여 실제 getter를 비공개 매크로 확장 프로퍼티와 연결합니다. 주입 대상 변수는 옵셔널(`?`) 또는 암시적 언래핑 옵셔널(`!`) 타입이어야 합니다.

### 마커 매크로

| 마크 | 설명 |
|------|------|
| `@Singleton` | 해당 의존성을 싱글톤(`.shared` 스코프)으로 주입 |
| `@NonImplement` | 표준 `[Type]Impl` 규칙이 없는 타입을 직접 컨테이너에서 검색 |
| `@Ignore` | 특정 변수를 DI 주입 대상에서 배제 |

---

## Container API

### 등록 (Register)

```swift
let container = Container()

// 타입으로 등록
container.register(impl: RepositoryImpl())

// 프로토콜 매핑으로 등록
container.register(protocol: Repository.self, impl: RepositoryImpl())

// 스코프 지정
container.register(impl: RepositoryImpl(), scope: .shared)
```

### 해결 (Resolve)

```swift
// 타입으로 해결
let repo = try container.resolve(RepositoryImpl.self)

// 프로토콜로 해결
let repo = try container.resolve(RepositoryImpl.self, protocol: Repository.self)

// 옵셔널 해결 (실패 시 nil)
let repo = container.resolveOptional(RepositoryImpl.self)
```

### 해제 (Unregister)

```swift
container.unregister(type: RepositoryImpl.self, protocol: Repository.self)
container.clearAll()
```

---

## License

MIT
