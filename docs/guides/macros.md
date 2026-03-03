# 매크로 가이드

ServiceAttach의 모든 매크로와 사용법을 안내합니다.

## 매크로 아키텍처

### BaseScopeMacro 프로토콜

모든 스코프 매크로(`@Instance`, `@Shared`, `@Weak`, `@Lazy`)는 `BaseScopeMacro` 프로토콜을 기반으로 구현됩니다. 이를 통해 매크로 간 중복 코드를 제거하고 일관된 동작을 보장합니다.

```swift
public protocol BaseScopeMacro: AccessorMacro {
    var scopeType: MacroScope { get }
    func validateOptionalType(_ type: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext)
}
```

**장점:**
- 코드 중복 제거: 모든 매크로가 공통 로직을 공유
- 일관된 에러 처리: 통합된 검증 로직
- 유지보수성 향상: 버그 수정이 모든 매크로에 적용

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
