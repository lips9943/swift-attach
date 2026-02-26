# Scope 시스템

ServiceAttach는 3가지 스코프를 제공하여 인스턴스의 생명주기를 제어합니다.

## 스코프 종류

| 스코프 | 매크로 | 동작 | 사용 사례 |
|--------|--------|------|-----------|
| transient | `@Instance` | 매번 새 인스턴스 | 상태 없는 서비스 |
| shared | `@Shared` | 싱글톤 | 설정, 리포지토리 |
| weak | `@Weak` | weak 참조 | 생명주기 연결 |

## transient

매번 접근할 때 새로운 인스턴스가 생성됩니다.

```swift
@Instance
var service: Service!

// 접근할 때마다 새 인스턴스
let a = service // Service 인스턴스 #1
let b = service // Service 인스턴스 #2

a === b // false
```

**사용 사례:**
- 상태가 없는 서비스
- 매번 새로운 컨텍스트가 필요한 경우

> **구현:** [`Scope`](../Sources/ServiceAttach/Containers/Container.swift) 열거형의 `transient` 케이스를 참조하세요.

## shared

앱 전체에서 공유되는 싱글톤 인스턴스입니다.

```swift
@Shared
var repository: Repository!

// 항상 같은 인스턴스
let a = repository // Repository 인스턴스 #1
let b = repository // Repository 인스턴스 #1 (동일)

a === b // true
```

**사용 사례:**
- 설정/구성 객체
- 데이터베이스 리포지토리
- 네트워크 매니저

## weak

weak 참조로 관리되며, 참조하는 객체가 해제되면 자동으로 정리됩니다.

```swift
@Weak(varName: "output")
var interactor: Interactor!
```

**사용 사례:**
- 뷰와 프레젠터 연결
- 생명주기가 연결된 객체

## @Lazy의 특별한 동작

`@Lazy`는 첫 접근 시 생성되지만 **weak scope**로 등록됩니다.

```swift
@Lazy
var heavyService: HeavyService

// 첫 접근 시 생성
heavyService.doSomething()

// 참조가 사라지면 자동 해제
```

상세한 내용은 [지연 초기화 가이드](advanced/lazy-loading.md)를 확인하세요.
