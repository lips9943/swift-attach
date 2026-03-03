# 마이그레이션 가이드

이 가이드는 Macro Quality Refactoring (2026-03-03) 이후의 변경사항과 마이그레이션 방법을 안내합니다.

## 개요

이번 리팩토링은 다음을 목표로 진행되었습니다:
- 매크로 코드 품질 개선
- Swift 6 Concurrency 모델 완전 준수
- 구조화된 에러 처리 시스템 도입
- 스레드 안전성 강화

## 기존 코드 호환성

**좋은 소식**: 모든 기존 코드는 변경 없이 작동합니다.

매크로 사용 방식은 완전히 동일합니다:

```swift
// 기존 코드 - 변경 없음
@Instance
var service: MyService!

@Shared
var repository: Repository!

@Weak(varName: "output")
var interactor: Interactor!

@Lazy
var lazyService: MyService

@Unregister(type: (Presenter.self, nil), (Router.self, nil))
class MyView {
    // deinit에서 자동으로 해제
}
```

## 새로운 기능

### 1. Throwing API (명시적 에러 처리)

```swift
// 새로운 방식 (명시적 에러 처리)
do {
    let service: MyService = try Container.shared.resolve(MyService.self)
    service.doSomething()
} catch ContainerError.typeNotRegistered(let type, let scope) {
    print("\(type) 타입이 \(scope) 스코프에 등록되지 않음")
} catch ContainerError.factoryReturnedNil(let type) {
    print("\(type) 팩토리가 nil을 반환함")
} catch {
    print("알 수 없는 에러: \(error)")
}
```

**이점:**
- 등록되지 않은 타입을 명확하게 처리
- 에러 원인을 정확히 파악
- 디버깅이 쉬워짐

### 2. Optional API (기존 방식 유지)

```swift
// 기존 방식 - 여전히 지원됨
if let service: MyService = Container.shared.resolveOptional(MyService.self) {
    service.doSomething()
}
```

**참고:** `resolveOptional`은 내부적으로 throwing API를 사용하며 에러를 무시하고 `nil`을 반환합니다.

### 3. 프로토콜 타입으로 등록/resolve

```swift
// 프로토콜 타입으로 등록
Container.shared.register(protocol: MyProtocol.self, impl: MyServiceImpl(), scope: .shared)

// 프로토콜 타입으로 resolve
do {
    let service: MyProtocol = try Container.shared.resolve(MyProtocol.self, protocol: MyProtocol.self, scope: .shared)
    service.doSomething()
} catch {
    print("Resolve 실패: \(error)")
}
```

## 내부 구현 변경

### Container의 Thread-Safety 개선

**변경 전:**
```swift
// NSLock 기반 수동 동기화
public class Container {
    private let lock = NSLock()

    public func register<T>(...) {
        lock.lock()
        defer { lock.unlock() }
        // ...
    }
}
```

**변경 후:**
```swift
// Actor 격리 + nonisolated 공개 API
public actor Container {
    private let storage = ContainerStorage() // NSLock 기반 동기화

    public nonisolated func register<T>(...) {
        // 내부적으로 storage.withLock 사용
    }
}
```

**이점:**
- Swift 6 Concurrency 모델 완전 준수
- 데이터 레이스 방지 보장
- `await` 없이 매크로에서 호출 가능
- 동시성 컨텍스트에서 안전하게 사용

### 매크로 아키텍처 개선

**변경 전:**
- 각 매크로가 독립적으로 구현
- 중복 코드 다수 존재
- 에러 처리 로직 중복

**변경 후:**
- `BaseScopeMacro` 프로토콜 도입
- 공통 로직 집중화
- 일관된 에러 처리

**이점:**
- 코드 중복 제거
- 유지보수성 향상
- 버그 수정이 모든 매크로에 적용

## ContainerError 타입

새로운 구조화된 에러 타입:

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
    print("\(type) 타입을 \(scope) 스코프에 먼저 등록해야 합니다")
} catch ContainerError.factoryReturnedNil(let type) {
    // 팩토리가 nil 반환
    print("\(type) 팩토리가 nil을 반환했습니다. 팩토리 구현을 확인하세요")
} catch {
    // 기타 에러
    print("예상치 못한 에러: \(error)")
}
```

## 마이그레이션 체크리스트

### 필수 항목 (없음)

이번 리팩토링은 **완전히 호환 가능**하므로 필수 변경사항이 없습니다.

### 권장 항목

1. **에러 처리 개선**
   ```swift
   // Before
   let service: MyService? = Container.shared.resolveOptional(MyService.self)
   if service == nil {
       print("서비스를 가져올 수 없음") // 왜 nil인지 알 수 없음
   }

   // After (권장)
   do {
       let service: MyService = try Container.shared.resolve(MyService.self)
   } catch {
       print("구체적인 에러: \(error)") // 왜 실패했는지 정확히 알 수 있음
   }
   ```

2. **프로토콜 기반 등록 활용**
   ```swift
   // Before
   Container.shared.register(impl: MyServiceImpl(), scope: .shared)

   // After (권장)
   Container.shared.register(protocol: MyProtocol.self, impl: MyServiceImpl(), scope: .shared)
   ```

## 테스트 검증

리팩토링 후 **44개 테스트** 모두 통과:

- BaseScopeMacroTests: 1 test
- ContainerErrorTests: 9 tests
- ContainerTests: 11 tests
- ConcurrencyTests: 8 tests (새로 추가됨)
- InstanceMacroTests: 2 tests
- LazyMacroTests: 3 tests
- ScopeTests: 3 tests
- SharedMacroTests: 2 tests
- UnregisterMacroTests: 2 tests
- WeakMacroTests: 2 tests
- ServiceAttachMacrosTests: 1 test

## 컴파일러 경고

이번 리팩토링으로 모든 컴파일러 경고가 해결되었습니다.

- `UnregisterMacro`의 프로토콜 조합 확장 경고 수정
- Conditional cast 경고 수정
- Actor isolation 관련 경고 해결

## 성능

내부 구현 변경으로 인한 성능 저하는 없습니다. 오히려 개선된 사항:

- 더 효율적인 lock 사용
- 불필요한 동기화 제거
- 최적화된 스토리지 접근

## 도움이 필요하신가요?

문제가 있거나 도움이 필요하시면 다음을 참조하세요:

- [이슈 트래커](https://github.com/yourusername/swift-attach/issues)
- [문서](docs/)
- [예제 코드](Sources/ServiceAttachClient/)

## 변경사항 요약

| 항목 | 변경 사항 | 호환성 |
|------|-----------|--------|
| 매크로 API | 변경 없음 | ✅ 완전 호환 |
| Container API | Throwing API 추가 | ✅ 기존 API 유지 |
| 내부 구현 | Actor 기반 리팩토링 | ✅ 사용자 코드 변경 불필요 |
| 에러 처리 | ContainerError 추가 | ✅ 선택적 사용 |
| 테스트 | 44개 테스트 통과 | ✅ 모두 통과 |
| 컴파일러 경고 | 모두 해결 | ✅ 경고 없음 |
