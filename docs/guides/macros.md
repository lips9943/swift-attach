# 매크로 가이드

ServiceAttach의 모든 매크로와 사용법을 안내합니다.

## @Instance

매번 새 인스턴스를 생성합니다.

### 기본 사용

```swift
@Instance
var service: MyService!
```

### 프로토콜에 구현체 주입

```swift
protocol MyProtocol {
    func doSomething()
}

class MyServiceImpl: MyProtocol {
    func doSomething() { "Implementing!" }
}

@Instance(impl: MyServiceImpl.self)
var service: MyProtocol!
```

## @Shared

싱글톤 인스턴스를 주입합니다.

```swift
@Shared
var repository: Repository!
```

## @Weak

weak 참조로 생명주기를 연결합니다.

```swift
@Weak(varName: "output")
var interactor: Interactor!
```

`varName`은 연결할 프로퍼티의 이름을 지정합니다.

## @Lazy

지연 초기화를 제공합니다.

```swift
@Lazy
var heavyService: HeavyService
```

### 구현체 지정

```swift
@Lazy(impl: MyServiceImpl.self)
var lazyProtocol: MyProtocol
```

## @Unregister

자동으로 인스턴스를 해제합니다.

```swift
@Unregister(type: (Presenter.self, nil), (Router.self, nil))
class MyView {
    // deinit에서 자동으로 해제
}
```

## 매크로 비교

| 매크로 | 스코프 | 옵셔널 | impl 파라미터 |
|--------|--------|--------|---------------|
| @Instance | transient | X | O |
| @Shared | shared | X | X |
| @Weak | weak | O (필수) | X |
| @Lazy | weak | X | O |
| @Unregister | - | - | - |

> **상세:** 각 매크로의 API 문서는 [코드 주석](../Sources/ServiceAttach/)을 확인하세요.
