# Container 사용법

매크로 없이 `Container`를 직접 사용하는 방법을 안내합니다.

## 스레드 안전성

ServiceAttach의 Container는 Swift 6 Concurrency 모델을 준수합니다.

- **내부 저장소**: `ContainerStorage` 클래스가 `NSLock` 기반 동기화로 스레드 안전성 보장
- **공개 API**: 모든 메서드가 `nonisolated`로 선언되어 `await` 없이 호출 가능
- **Actor 격리**: 내부 상태는 actor로 보호되면서 외부에서는 간편하게 사용

## 인스턴스 등록

```swift
// shared 스코프로 등록
Container.shared.register(impl: MyService(), scope: .shared)

// transient 스코프로 등록 (기본)
Container.shared.register(impl: MyService())

// weak 스코프로 등록
Container.shared.register(impl: MyService(), scope: .weak)

// 프로토콜 타입으로 등록
Container.shared.register(protocol: MyProtocol.self, impl: MyServiceImpl(), scope: .shared)
```

## 인스턴스 resolve

### Optional resolve (기본)

```swift
// 타입으로 resolve - nil이 반환될 수 있음
if let service: MyService = Container.shared.resolveOptional(MyService.self, scope: .shared) {
    service.doSomething()
}
```

### Throwing resolve (명시적 에러 처리)

```swift
// 등록되지 않은 타입을 resolve하면 ContainerError 발생
do {
    let service: MyService = try Container.shared.resolve(MyService.self, scope: .shared)
    service.doSomething()
} catch ContainerError.typeNotRegistered(let type, let scope) {
    print("'\(type)' 타입이 '\(scope)' 스코프에 등록되지 않았습니다")
} catch {
    print("기타 에러: \(error)")
}
```

### 프로토콜 타입으로 resolve

```swift
// 프로토콜으로 등록된 구현체 resolve
do {
    let service: MyProtocol = try Container.shared.resolve(MyProtocol.self, protocol: MyProtocol.self, scope: .shared)
    service.doSomething()
} catch {
    print("Resolve 실패: \(error)")
}
```

## 인스턴스 해제

```swift
// 특정 타입 해제
Container.shared.unregister(MyService.self)

// 프로토콜 타입 해제
Container.shared.unregister(MyService.self, protocol: MyProtocol.self)

// 여러 타입 한번에 해제
Container.shared.unregisterObjects((MyService.self, nil), (MyProtocol.self, nil))
```

## 에러 처리

ServiceAttach는 구조화된 에러 처리를 제공합니다:

```swift
public enum ContainerError: Error, Sendable {
    case typeNotRegistered(type: String, scope: String)
    case resolutionFailed(type: String, scope: String, underlying: Error)
    case invalidScope(type: String, scope: Scope)
    case factoryReturnedNil(type: String)
    case containerDestroyed
}
```

**사용 예시:**

```swift
do {
    let service: MyService = try Container.shared.resolve(MyService.self)
} catch ContainerError.typeNotRegistered(let type, let scope) {
    // 타입이 등록되지 않음
    print("\(type) 타입이 \(scope) 스코프에 등록되지 않음")
} catch ContainerError.factoryReturnedNil(let type) {
    // 팩토리가 nil 반환
    print("\(type) 팩토리가 nil을 반환함")
} catch {
    // 기타 에러
    print("알 수 없는 에러: \(error)")
}
```

## 스코프 종류

| 스코프 | 설명 | 사용 예시 |
|--------|------|----------|
| `.transient` | 매번 새 인스턴스 생성 | 임시 객체, 상태 없는 서비스 |
| `.shared` | 싱글톤 인스턴스 | 설정 관리자, 네트워크 매니저 |
| `.weak` | weak 참조, 자동 해제 | 수명周期 연결, 순환 참조 방지 |

> **구현:** [`Container`](../Sources/ServiceAttach/Containers/Container.swift) 소스 코드를 참조하세요.
