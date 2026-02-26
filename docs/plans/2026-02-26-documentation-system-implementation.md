# 문서화 시스템 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** ServiceAttach 프로젝트의 문서화 시스템 구축 - README.md, docs/ 폴더 구조, DocC 코드 주석, 자동화 스크립트 포함

**Architecture:** C형 하이브리드 접근 - DocC 표준 주석으로 API 레퍼런스 자동 생성, 수동 가이드로 학습 순서 지원, 단일 진실 공급원 원칙으로 중복 최소화

**Tech Stack:** Swift DocC, Markdown, Bash scripts, Makefile

---

## Phase 1: README.md 작성

### Task 1: README.md 파일 생성

**Files:**
- Create: `README.md`

**Step 1: README.md 내용 작성**

```markdown
# ServiceAttach

Swift Macros를 사용한 타입 안전 의존성 주입 라이브러리

[![Swift](https://img.shields.io/badge/Swift-6.2%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 개요

ServiceAttach는 Swift Compiler Plugin과 Macro 시스템을 활용하여
컴파일 타임에 코드를 생성하는 의존성 주입 라이브러리입니다.

### 핵심 기능

- **@Instance** - 매번 새 인스턴스 생성 (transient scope)
- **@Shared** - 싱글톤 인스턴스 (shared scope)
- **@Weak** - weak 참조로 생명주기 자동 관리
- **@Lazy** - 지연 초기화 (첫 접근 시 생성)
- **@Unregister** - 자동 등록 해제

## 빠른 시작

### 1. 의존성 추가

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-attach", from: "1.0.0")
]
```

### 2. 기본 사용

```swift
import ServiceAttach

@Shared
var repository: Repository!

@Instance
var service: Service!
```

### 3. 빌드 및 실행

```bash
swift build
swift run ServiceAttachClient
```

## 문서

| 문서 | 설명 |
|------|------|
| [시작하기](docs/getting-started.md) | 설치부터 첫 예제까지 |
| [가이드](docs/guides/) | 개념별 상세 가이드 |
| [아키텍처](docs/architecture/) | 내부 구현과 기여 방법 |
| [API 레퍼런스](docs/api/) | 전체 API 문서 (DocC) |

## 예시

```swift
// 프로토콜에 구현체 주입
@Instance(impl: MyServiceImpl.self)
var service: MyProtocol!

// 지연 초기화
@Lazy
var heavyService: HeavyService
```

## 라이선스

MIT License - [LICENSE](LICENSE) 참조
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with project overview and quick start"
```

---

## Phase 2: DocC 코드 주석 추가

### Task 2: ServiceAttach 모듈 헤더 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Containers/Container.swift` (파일 상단 추가)

**Step 1: 파일 헤더 주석 추가**

`Sources/ServiceAttach/Containers/Container.swift` 파일의 맨 위에 다음 주석 추가:

```swift
/// Swift Macros를 사용한 의존성 주입(Dependency Injection) 라이브러리입니다.
///
/// ServiceAttach는 컴파일 타임에 매크로를 확장하여
/// 타입 안전한 의존성 주입을 제공합니다.
///
/// - Important: Swift 6.2+가 필요합니다.
///
/// ## Topics
///
/// ### Macros
/// - ``Instance``
/// - ``Shared``
/// - ``Weak``
/// - ``Lazy``
/// - ``Unregister``
///
/// ### Containers
/// - ``Container``
/// - ``Scope``
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Containers/Container.swift
git commit -m "docs: add module header documentation comment"
```

---

### Task 3: Container.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Containers/Container.swift`
- Read: `Sources/ServiceAttach/Containers/Container.swift` (구조 확인)

**Step 1: Container.swift 읽기**

```bash
cat Sources/ServiceAttach/Containers/Container.swift
```

**Step 2: Container 열거형 주석 추가**

`Container` enum 정의 위에:

```swift
/// 의존성 주입을 위한 컨테이너입니다.
///
/// `Container`는 객체의 생명주기를 관리하고 인스턴스를 등록/해제합니다.
public enum Container {
    // ...
}
```

**Step 3: Scope 열거형 주석 추가**

`Scope` enum 정의 위에:

```swift
/// 인스턴스의 생명주기(스코프)를 정의합니다.
///
/// 스코프는 인스턴스가 얼마나 오래 유지되는지 결정합니다.
public enum Scope {
    /// 매번 새 인스턴스를 생성합니다.
    case transient

    /// 앱 전체에서 공유되는 싱글톤 인스턴스입니다.
    case shared

    /// weak 참조로 관리되는 인스턴스입니다.
    case weak
}
```

**Step 4: 메서드 주석 추가**

각 public 메서드 위에 DocC 주석 추가:

```swift
/// 지정된 타입과 이름으로 인스턴스를 resolve합니다.
///
/// - Parameters:
///   - type: resolve할 타입
///   - name: 인스턴스 이름 (기본값: nil)
/// - Returns: resolve된 인스턴스 또는 nil
public static func resolve<T>(_ type: T.Type, name: String? = nil) -> T? {
    // ...
}
```

**Step 5: Commit**

```bash
git add Sources/ServiceAttach/Containers/Container.swift
git commit -m "docs: add DocC comments to Container and Scope"
```

---

### Task 4: Instance.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Instance.swift`

**Step 1: Instance 매크로 주석 추가**

```swift
/// Service의 인스턴스를 매번 새로 생성하여 주입합니다.
///
/// `@Instance`는 **transient scope**를 사용하여,
/// 접근할 때마다 새로운 인스턴스가 생성됩니다.
///
/// ```swift
/// @Instance
/// var service: MyService!
///
/// func useService() {
///     service.doSomething() // 매번 새 인스턴스
/// }
/// ```
///
/// - Important: 옵셜 타입(`Type?`)은 지원하지 않습니다.
/// - Note: 프로토콜 타입에 주입 시 `impl` 파라미터로 구현체를 지정하세요.
///
/// ### Example
/// ```swift
/// // 구현체 지정 (프로토콜)
/// @Instance(impl: MyServiceImpl.self)
/// var service: MyProtocol!
/// ```
///
/// - Tag: instanceMacro
@attached(accessor, names: named(getter))
public macro Instance(impl: Any.Type? = nil) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "InstanceMacro"
)
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Instance.swift
git commit -m "docs: add DocC comments to @Instance macro"
```

---

### Task 5: Shared.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Shared.swift`

**Step 1: Shared 매크로 주석 추가**

```swift
/// 싱글톤 인스턴스를 주입합니다.
///
/// `@Shared`는 **shared scope**를 사용하여,
/// 앱 전체에서 공유되는 단일 인스턴스를 제공합니다.
///
/// ```swift
/// @Shared
/// var repository: Repository!
///
/// // 항상 같은 인스턴스
/// repository === repository // true
/// ```
///
/// - Important: 옵셜 타입(`Type?`)은 지원하지 않습니다.
/// - Note: 상태를 유지해야 하는 객체에 적합합니다.
///
/// - Tag: sharedMacro
@attached(accessor, names: named(getter))
public macro Shared() = #externalMacro(
    module: "ServiceAttachMacros",
    type: "SharedMacro"
)
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Shared.swift
git commit -m "docs: add DocC comments to @Shared macro"
```

---

### Task 6: Weak.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Weak.swift`

**Step 1: Weak 매크로 주석 추가**

```swift
/// weak 참조로 인스턴스를 주입합니다.
///
/// `@Weak`는 **weak scope**를 사용하여,
/// 참조하는 객체가 해제되면 자동으로 인스턴스도 해제됩니다.
///
/// ```swift
/// @Weak(varName: "output")
/// var interactor: Interactor!
/// ```
///
/// - Important: 반드시 암시적으로 언래핑된 옵셜 타입(`Type!`)이어야 합니다.
/// - Parameter varName: 연결할 프로퍼티 이름
///
/// - Tag: weakMacro
@attached(accessor, names: named(getter))
public macro Weak(varName: String) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "WeakMacro"
)
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Weak.swift
git commit -m "docs: add DocC comments to @Weak macro"
```

---

### Task 7: Lazy.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Lazy.swift`

**Step 1: Lazy 매크로 주석 추가**

```swift
/// 지연 초기화 인스턴스를 주입합니다.
///
/// `@Lazy`는 첫 접근 시 인스턴스를 생성하고,
/// **weak scope**로 자동 등록합니다.
///
/// ```swift
/// @Lazy
/// var heavyService: HeavyService
///
/// // 첫 접근 시 생성
/// heavyService.doSomething()
/// ```
///
/// - Note: 프로토콜 타입에 주입 시 `impl` 파라미터로 구현체를 지정하세요.
///
/// ### Example
/// ```swift
/// @Lazy(impl: MyServiceImpl.self)
/// var lazyProtocol: MyProtocol
/// ```
///
/// - Tag: lazyMacro
@attached(accessor, names: named(getter))
public macro Lazy(impl: Any.Type? = nil) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "LazyMacro"
)
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Lazy.swift
git commit -m "docs: add DocC comments to @Lazy macro"
```

---

### Task 8: Unregister.swift DocC 주석 추가

**Files:**
- Modify: `Sources/ServiceAttach/Unregister.swift`

**Step 1: Unregister 매크로 주석 추가**

```swift
/// 객체 해제 시 자동으로 등록된 인스턴스를 제거합니다.
///
/// `@Unregister`는 `deinit`에서 자동으로 `unregisterObjects()`를 호출하여
/// weak 참조로 연결된 인스턴스를 정리합니다.
///
/// ```swift
/// @Unregister(type: (Presenter.self, nil), (Router.self, nil))
/// class MyView {
///     // deinit에서 자동으로 unregisterObjects() 호출
/// }
/// ```
///
/// - Parameter type: 해제할 타입과 이름의 튜플 목록
///
/// - Tag: unregisterMacro
@attached(member, names: named(deinit))
public macro Unregister(type: Any...) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "UnregisterMacro"
)
```

**Step 2: Commit**

```bash
git add Sources/ServiceAttach/Unregister.swift
git commit -m "docs: add DocC comments to @Unregister macro"
```

---

## Phase 3: docs/getting-started.md 작성

### Task 9: getting-started.md 작성

**Files:**
- Create: `docs/getting-started.md`

**Step 1: getting-started.md 내용 작성**

```markdown
# ServiceAttach 시작하기

ServiceAttach를 사용하여 Swift 프로젝트에 의존성 주입을 적용하는 방법을 안내합니다.

## 설치

### Swift Package Manager

`Package.swift`에 의존성을 추가합니다:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-attach", from: "1.0.0")
]

// 타겟 의존성
.targets(
    name: "MyApp",
    dependencies: ["ServiceAttach"]
)
```

Xcode에서는 **File → Add Package Dependencies...**에서 패키지 URL을 추가하세요.

## 첫 번째 예제

### 1. 기본 서비스 정의

```swift
import ServiceAttach

// 서비스 클래스
class UserService {
    func greet() -> String {
        "Hello, ServiceAttach!"
    }
}
```

### 2. @Shared로 싱글톤 주입

```swift
@Shared
var userService: UserService!

func greetUser() {
    print(userService.greet()) // "Hello, ServiceAttach!"
}
```

### 3. @Instance로 매번 새 인스턴스

```swift
@Instance
var logger: Logger!

func logSomething() {
    logger.log("Something happened") // 매번 새 Logger 인스턴스
}
```

## 다음 단계

- [Scope 가이드](guides/scopes.md) - 스코프 시스템 이해하기
- [매크로 가이드](guides/macros.md) - 모든 매크로 상세 사용법
- [API 레퍼런스](api/) - 전체 API 문서
```

**Step 2: Commit**

```bash
git add docs/getting-started.md
git commit -m "docs: add getting-started guide"
```

---

## Phase 4: docs/guides/ 작성

### Task 10: docs/guides/scopes.md 작성

**Files:**
- Create: `docs/guides/scopes.md`

**Step 1: scopes.md 내용 작성**

```markdown
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
```

**Step 2: Commit**

```bash
git add docs/guides/scopes.md
git commit -m "docs: add scopes guide"
```

---

### Task 11: docs/guides/macros.md 작성

**Files:**
- Create: `docs/guides/macros.md`

**Step 1: macros.md 내용 작성**

```markdown
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
```

**Step 2: Commit**

```bash
git add docs/guides/macros.md
git commit -m "docs: add macros guide"
```

---

### Task 12: docs/guides/container.md 작성

**Files:**
- Create: `docs/guides/container.md`

**Step 1: container.md 내용 작성**

```markdown
# Container 사용법

매크로 없이 `Container`를 직접 사용하는 방법을 안내합니다.

## 인스턴스 등록

```swift
// shared 스코프로 등록
Container.register(MyService(), scope: .shared)

// weak 스코프로 이름 지정하여 등록
Container.register(interactor, scope: .weak, name: "output")
```

## 인스턴스 resolve

```swift
// 타입으로 resolve
if let service: MyService = Container.resolve(MyService.self) {
    service.doSomething()
}

// 이름으로 resolve
if let interactor: Interactor = Container.resolve(Interactor.self, name: "output") {
    interactor.doSomething()
}
```

## 인스턴스 해제

```swift
// 특정 타입 해제
Container.unregister(MyService.self)

// 이름으로 해제
Container.unregister(Interactor.self, name: "output")

// 여러 타입 한번에 해제
Container.unregisterObjects((MyService.self, nil), (Interactor.self, "output"))
```

> **구현:** [`Container`](../Sources/ServiceAttach/Containers/Container.swift) 소스 코드를 참조하세요.
```

**Step 2: Commit**

```bash
git add docs/guides/container.md
git commit -m "docs: add container usage guide"
```

---

### Task 13: docs/guides/advanced/lazy-loading.md 작성

**Files:**
- Create: `docs/guides/advanced/lazy-loading.md`

**Step 1: lazy-loading.md 내용 작성**

```markdown
# 지연 초기화 (Lazy Loading)

`@Lazy` 매크로를 사용하여 인스턴스의 생성을 지연시키는 방법을 안내합니다.

## 기본 개념

`@Lazy`는 첫 접근 시 인스턴스를 생성하고, **weak scope**로 자동 등록합니다.

### 일반적인 사용

```swift
@Lazy
var heavyService: HeavyService

// 첫 접근 시 생성됨
heavyService.doSomething()

// 이후 접근은 같은 인스턴스
heavyService.doSomethingElse()
```

## 동작 방식

1. 첫 접근 시 `Container`에 인스턴스 생성 및 등록 (weak scope)
2. 이후 접근은 등록된 인스턴스 반환
3. 참조가 모두 사라지면 자동 해제

## 프로토콜에 구현체 지정

```swift
@Lazy(impl: MyServiceImpl.self)
var lazyProtocol: MyProtocol
```

## 사용 사례

- 초기화 비용이 큰 객체
- 사용되지 않을 수 있는 기능
- 메모리를 효율적으로 관리해야 하는 경우
```

**Step 2: Commit**

```bash
git add docs/guides/advanced/lazy-loading.md
git commit -m "docs: add lazy loading guide"
```

---

### Task 14: docs/guides/advanced/error-handling.md 작성

**Files:**
- Create: `docs/guides/advanced/error-handling.md`

**Step 1: error-handling.md 내용 작성**

```markdown
# 에러 처리

ServiceAttach의 컴파일 타임 에러와 해결 방법을 안내합니다.

## 컴파일 타임 에러

### nameNotFound

이름을 찾을 수 없습니다.

```swift
// 에러: name을 지정해야 합니다
@Weak()
var service: Service!

// 수정
@Weak(varName: "output")
var service: Service!
```

### noOptionalSupported

옵셜 타입은 지원하지 않습니다.

```swift
// 에러: 옵셜 타입 사용
@Instance
var service: Service?

// 수정
@Instance
var service: Service!
```

### onlyOptionalSupported

옵셜 타입만 지원합니다.

```swift
// 에러: 옵셜이 아님
@Weak(varName: "output")
var service: Service

// 수정
@Weak(varName: "output")
var service: Service!
```

> **구현:** [`MacroError`](../Sources/ServiceAttachMacros/MacroError.swift)에서 모든 에러 케이스를 확인하세요.
```

**Step 2: Commit**

```bash
git add docs/guides/advanced/error-handling.md
git commit -m "docs: add error handling guide"
```

---

## Phase 5: docs/architecture/ 작성

### Task 15: docs/architecture/overview.md 작성

**Files:**
- Create: `docs/architecture/overview.md`

**Step 1: overview.md 내용 작성**

```markdown
# 아키텍처 개요

ServiceAttach의 전체 아키텍처와 구조를 안내합니다.

## 타겟 구조

프로젝트는 3개의 주요 타겟으로 구성됩니다:

```
┌─────────────────────────────────────────────┐
│           ServiceAttach (Public)            │
│        사용자 공개 API (매크로 선언)          │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│       ServiceAttachMacros (Plugin)          │
│      매크로 구현 + 코드 생성                 │
└─────────────────┬───────────────────────────┘
                  │
          컴파일 타임 코드 생성
                  │
┌─────────────────▼───────────────────────────┐
│          생성된 getter 코드                  │
│    Container.resolve/register 호출         │
└─────────────────────────────────────────────┘
```

### 1. ServiceAttach (Public Library)

사용자가 사용하는 공개 API를 제공합니다.

- **위치:** `Sources/ServiceAttach/`
- **주요 파일:**
  - `Instance.swift` - `@Instance` 매크로 선언
  - `Shared.swift` - `@Shared` 매크로 선언
  - `Weak.swift` - `@Weak` 매크로 선언
  - `Lazy.swift` - `@Lazy` 매크로 선언
  - `Unregister.swift` - `@Unregister` 매크로 선언
  - `Containers/` - DI 컨테이너 구현

### 2. ServiceAttachMacros (Compiler Plugin)

매크로 실제 구현이 포함된 컴파일러 플러그인입니다.

- **위치:** `Sources/ServiceAttachMacros/`
- **주요 파일:**
  - `ServiceAttachMacro.swift` - CompilerPlugin 진입점
  - `Macros/` - 각 매크로 구현
  - `MacroError.swift` - 에러 정의
  - `Helper.swift` - 헬퍼 함수

### 3. ServiceAttachClient (Example)

사용 예제를 보여주는 실행 가능한 클라이언트입니다.

- **위치:** `Sources/ServiceAttachClient/`

## 매크로 확장 흐름

1. 컴파일러가 `@Instance` 등의 매크로 발견
2. `ServiceAttachMacros` 플러그인 호출
3. `AccessorMacro` 프로토콜 구현이 getter 코드 생성
4. 생성된 코드가 컴파일됨

## Scope 시스템

[`Container`](../Sources/ServiceAttach/Containers/Container.swift)에 정의된 3가지 스코프:

- **transient** - 매번 새 인스턴스
- **shared** - 싱글톤
- **weak** - weak 참조

상세한 내용은 [macro-system.md](macro-system.md)를 확인하세요.
```

**Step 2: Commit**

```bash
git add docs/architecture/overview.md
git commit -m "docs: add architecture overview"
```

---

### Task 16: docs/architecture/macro-system.md 작성

**Files:**
- Create: `docs/architecture/macro-system.md`
- Read: `Sources/ServiceAttachMacros/Macros/InstanceMacro.swift`

**Step 1: InstanceMacro.swift 구조 확인**

```bash
cat Sources/ServiceAttachMacros/Macros/InstanceMacro.swift
```

**Step 2: macro-system.md 내용 작성**

```markdown
# 매크로 시스템

ServiceAttach의 매크로 구현 원리를 안내합니다.

## 매크로 구현 패턴

모든 매크로는 `AccessorMacro` 프로토콜을 따릅니다.

```swift
public struct InstanceMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax]
}
```

## 매크로 확장 단계

1. **인자 파싱** - `node.arguments`에서 파라미터 추출
2. **검증** - `VariableDeclSyntax` 확인 및 유효성 검사
3. **타입 추출** - 프로퍼티 타입 파싱
4. **에러 처리** - `MacroError`로 컴파일 타임 에러 생성
5. **코드 생성** - getter 생성 (`Container.resolveOptional` 호출)

## 생성되는 코드

`@Instance`가 붙은 프로퍼티는 다음과 같은 getter가 생성됩니다:

```swift
var service: Service! {
    get {
        guard let instance: Service = Container.resolve(Service.self) else {
            fatalError("Service 인스턴스를 찾을 수 없습니다")
        }
        return instance
    }
}
```

## MacroError

[`MacroError.swift`](../../Sources/ServiceAttachMacros/MacroError.swift)에 정의된 에러:

- `nameNotFound` - 이름을 찾을 수 없습니다
- `typeNotSupported` - 지원하지 않는 타입입니다
- `expressionRequired` - 매개변수가 필요합니다
- `noInheritance` - 상속 타입이 없습니다
- `noOptionalSupported` - 옵셜을 지원하지 않습니다
- `onlyOptionalSupported` - 옵셜만 지원합니다

## 매크로 추가 방법

1. `Sources/ServiceAttach/`에 공개 매크로 선언 추가
2. `Sources/ServiceAttachMacros/Macros/`에 구현체 추가
3. `ServiceAttachMacro.swift`의 `providingMacros` 배열에 등록
4. `MacroError.swift`에 필요한 에러 케이스 추가
5. 테스트 파일 추가
```

**Step 3: Commit**

```bash
git add docs/architecture/macro-system.md
git commit -m "docs: add macro system documentation"
```

---

### Task 17: docs/architecture/contributing.md 작성

**Files:**
- Create: `docs/architecture/contributing.md`

**Step 1: contributing.md 내용 작성**

```markdown
# 기여 가이드

ServiceAttach 프로젝트에 기여하는 방법을 안내합니다.

## 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/yourusername/swift-attach.git
cd swift-attach

# 의존성 설치
swift package resolve

# 빌드
swift build

# 테스트
swift test
```

## 코드 스타일

- Swift API Design Guidelines 준수
- DocC 주석으로 모든 공개 API 문서화
- 한국어로 주석 및 문서 작성

## 매크로 추가 체크리스트

1. `Sources/ServiceAttach/`에 공개 매크로 선언 추가
2. `Sources/ServiceAttachMacros/Macros/`에 구현체 추가
3. `ServiceAttachMacro.swift`에 매크로 등록
4. `MacroError.swift`에 에러 케이스 추가
5. 테스트 파일 추가

## 문서화

문서 변경 시 다음을 확인하세요:

- [ ] DocC 주석 업데이트
- [ ] 관련 docs/ 문서 업데이트
- [ ] `make docs` 실행 확인

## 테스트

```bash
# 전체 테스트
swift test

# 특정 테스트
swift test --filter InstanceMacroTests
```

## PR 제출

1. 브랜치 생성: `git checkout -b feature/my-feature`
2. 변경 및 커밋
3. PR 생성: 변경 사항과 테스트 결과 포함
```

**Step 2: Commit**

```bash
git add docs/architecture/contributing.md
git commit -m "docs: add contributing guide"
```

---

## Phase 6: 자동화 스크립트

### Task 18: DocC 생성 스크립트 추가

**Files:**
- Create: `scripts/docs/generate.sh`

**Step 1: scripts 폴더 생성**

```bash
mkdir -p scripts/docs
```

**Step 2: generate.sh 작성**

```bash
#!/bin/bash
# DocC 문서 자동 생성 스크립트

set -e

OUTPUT_DIR="docs/api"
SOURCE_MODULE="ServiceAttach"

echo "📚 DocC 문서 생성 중..."

swift package generate-documentation \
  --target $SOURCE_MODULE \
  --output-path $OUTPUT_DIR \
  --transform-for-static-hosting \
  --hosting-base-path /api \
  --index

echo "✅ 문서가 $OUTPUT_DIR 에 생성되었습니다"
```

**Step 3: 실행 권한 추가**

```bash
chmod +x scripts/docs/generate.sh
```

**Step 4: Commit**

```bash
git add scripts/docs/generate.sh
git commit -m "docs: add DocC generation script"
```

---

### Task 19: Makefile 추가

**Files:**
- Create: `Makefile`

**Step 1: Makefile 작성**

```makefile
.PHONY: docs help clean

help:
	@echo "사용 가능한 명령어:"
	@echo "  make docs    - DocC 문서 생성"
	@echo "  make clean   - 빌드 정리"
	@echo "  make test    - 테스트 실행"

docs:
	./scripts/docs/generate.sh

clean:
	swift build --clean

test:
	swift test
```

**Step 2: Commit**

```bash
git add Makefile
git commit -m "docs: add Makefile with docs command"
```

---

### Task 20: .github PR 템플릿 추가

**Files:**
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

**Step 1: .github 폴더 생성**

```bash
mkdir -p .github
```

**Step 2: PR 템플릿 작성**

```markdown
## PR 체크리스트

- [ ] 코드 변경사항 반영
- [ ] 관련 DocC 주석 업데이트
- [ ] `make docs` 실행 및 문서 생성 확인
- [ ] docs/ 문서 (수동 작성분) 업데이트 필요시 반영

## 변경사항

<!--简要描述 변경 내용 -->

## 관련 문서

<!-- 변경된 API 문서 링크 등 -->
```

**Step 3: Commit**

```bash
git add .github/PULL_REQUEST_TEMPLATE.md
git commit -m "docs: add PR template"
```

---

## Phase 7: 검증 및 완료

### Task 21: DocC 문서 생성 테스트

**Step 1: DocC 문서 생성**

```bash
make docs
```

Expected: `docs/api/` 폴더에 문서가 생성됨

**Step 2: 문서 구조 확인**

```bash
ls -la docs/api/
```

Expected: `index/`, `documentation/` 폴더 존재

**Step 3: README 문서 링크 검증**

```bash
# README.md의 링크들이 유효한지 확인
grep -o '\[.*\](docs/[^)]*)' README.md
```

---

### Task 22: 문서 완성도 확인

**Step 1: 성공 기준 체크**

```bash
# README.md 존재
ls -la README.md

# docs/ 구조 확인
ls -la docs/getting-started.md
ls -la docs/guides/
ls -la docs/architecture/

# DocC 주석 확인 (예시)
grep -r "///" Sources/ServiceAttach/*.swift | head -5

# 스크립트 확인
ls -la scripts/docs/generate.sh
ls -la Makefile
```

**Step 2: 모든 파일 커밋**

```bash
git add -A
git commit -m "docs: complete documentation system implementation"
```

---

## 요약

구현이 완료되면 다음이 생성됩니다:

1. **README.md** - 프로젝트 개요 및 빠른 시작
2. **DocC 주석** - 모든 공개 API에 문서 주석
3. **docs/getting-started.md** - 시작 가이드
4. **docs/guides/** - scopes, macros, container, advanced 가이드
5. **docs/architecture/** - overview, macro-system, contributing
6. **scripts/docs/generate.sh** - DocC 생성 스크립트
7. **Makefile** - 문서 빌드 명령어
8. **.github/PULL_REQUEST_TEMPLATE.md** - PR 템플릿
