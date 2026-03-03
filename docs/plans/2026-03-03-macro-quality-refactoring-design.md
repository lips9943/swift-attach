# 매크로 품질 및 스레드 안전성 개선 설계

**날짜:** 2026-03-03
**상태:** Design
**우선순위:** 높음

## 개요

ServiceAttach 프로젝트의 매크로 코드 품질, 스레드 안전성, 에러 처리 시스템을 개선하여 Swift 6 Concurrency 모델에 완전히 준수하는 견고한 의존성 주입 라이브러리로 발전시킵니다.

## 현재 문제점

### 1. 매크로 코드 중복
- InstanceMacro, SharedMacro, WeakMacro, LazyMacro에 상당히 유사한 코드 존재
- 인자 파싱, 타입 처리, 검증 로직이 각 매크로마다 반복
- Helper.removeSpecialCharacters()가 광범위하게 사용되지만 일관성 부족

### 2. 스레드 안전성
- Container가 `nonisolated(unsafe)` 키워드 사용
- NSLock 기반 수동 동기화는 Swift Concurrency 모델과 충돌 가능성
- actor-isolated 방식으로의 전환이 필요

### 3. 에러 처리
- 런타임 에러 처리가 `fatalError`로만 구현됨 (주석 처리됨)
- 컴파일 타임 에러(MacroError)는 존재하지만 일부 사용되지 않음
- WeakMacro의 `typeMustHaveInterrogationMark` 에러가 발동하지 않는 버그 존재

### 4. 컴파일러 경고
- WeakMacro.swift:26 - `varName`이 변경되지 않음
- Container.swift:190, 207 - 불필요한 conditional cast
- UnregisterMacro - protocol composition extension 경고

## 개선 방안

### 1. 매크로 아키텍처 리팩토링

#### BaseScopeMacro 프로토콜 도입

```swift
protocol BaseScopeMacro: AccessorMacro {
    var scopeType: Scope { get }
    func getResolveCode(type: String, impl: String?) -> String
}

extension BaseScopeMacro {
    func expand(
        _ attribute: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 공통 로직:
        // 1. VariableDeclSyntax 검증
        // 2. 인자 파싱 (parseArguments)
        // 3. 타입 정제 (Helper.removeSpecialCharacters)
        // 4. getResolveCode 위임하여 코드 생성
    }

    private func parseArguments(from node: AttributeSyntax) throws -> (type: String, impl: String?) {
        // 인자 파싱 로직 (중복 제거)
    }
}
```

#### 각 매크로 구현

```swift
struct InstanceMacro: BaseScopeMacro {
    let scopeType: Scope = .transient

    func getResolveCode(type: String, impl: String?) -> String {
        """
        get {
            Container.resolveOptional(type: \(type).self, impl: \(impl ?? "nil"))
        }
        """
    }
}

struct SharedMacro: BaseScopeMacro {
    let scopeType: Scope = .shared
    // 동일한 패턴
}

struct WeakMacro: BaseScopeMacro {
    let scopeType: Scope = .weak

    func getResolveCode(type: String, impl: String?) -> String {
        // weak 스코프 코드
    }

    // 옵셔널 검증 로직 추가
    private func validateOptionalType(_ type: String) throws {
        if !type.contains("?") {
            throw MacroError.typeMustHaveInterrogationMark
        }
    }
}

struct LazyMacro: BaseScopeMacro {
    let scopeType: Scope = .weak  // 지연 초기화 후 weak 스코프

    func getResolveCode(type: String, impl: String?) -> String {
        // 지연 초기화 코드
    }
}
```

#### 이점
- 코드 중복 최소화
- 유지보수성 향상
- 새로운 스코프 매크로 추가 용이성
- 버그 수정의 단일 지점

### 2. Actor 기반 Container

#### 기존 (NSLock 기반)

```swift
public final class Container {
    private let lock = NSLock()
    private var storage: [String: Any] = [:]

    nonisolated(unsafe) public static let shared = Container()

    func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        // ...
    }
}
```

#### 개선 (Actor 기반)

```swift
public actor Container {
    private var storage: [String: Any] = [:]
    private var singletonStorage: [String: Any] = [:]
    private var weakStorage: [String: WeakBox<AnyObject>] = [:]

    public static let shared = Container()

    // actor-isolated: 자동으로 스레드 안전성 보장
    public func resolve<T>(_ type: T.Type) throws -> T {
        // NSLock 없이 actor가 동기화 처리
    }

    public func resolveOptional<T>(_ type: T.Type) -> T? {
        try? resolve(type)
    }
}
```

#### 이점
- Swift 6 Concurrency 모델 완전 준수
- `nonisolated(unsafe)` 제거
- 컴파일 타임 데이터 레이스 방지
- 더 명확한 비동기 API (`await` 지원)

### 3. 구조화된 에러 처리 시스템

#### ContainerError 타입 도입

```swift
public enum ContainerError: Error, Sendable {
    case typeNotRegistered(type: String)
    case resolutionFailed(type: String, underlying: Error)
    case invalidScope(type: String, scope: Scope)
    case factoryReturnedNil(type: String)
    case containerDestroyed
}

extension ContainerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .typeNotRegistered(let type):
            return "'\(type)' 타입이 컨테이너에 등록되지 않았습니다."
        case .resolutionFailed(let type, let underlying):
            return "'\(type)' 타입 확인 실패: \(underlying.localizedDescription)"
        case .invalidScope(let type, let scope):
            return "'\(type)' 타입은 '\(scope)' 스코프를 지원하지 않습니다."
        case .factoryReturnedNil(let type):
            return "'\(type)' 팩토리가 nil을 반환했습니다."
        case .containerDestroyed:
            return "컨테이너가 이미 해제되었습니다."
        }
    }
}
```

#### 이중 API 제공

```swift
public actor Container {
    // Throwing 버전 (새로운 권장 방식)
    public func resolve<T>(_ type: T.Type) throws -> T {
        guard let factory = storage[key] else {
            throw ContainerError.typeNotRegistered(type: String(describing: type))
        }
        // ...
    }

    // Non-throwing 버전 (기존 호환성)
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        try? resolve(type)
    }
}
```

#### 매크로 에러 검증 강화

```swift
// WeakMacro에서 옵셔널 검증 버그 수정
private func validateOptionalType(_ type: String) throws {
    if !type.contains("?") {
        throw MacroError.typeMustHaveInterrogationMark
    }
}
```

#### 이점
- Graceful degradation
- 디버깅 용이성
- 기존 코드 호환성 유지
- 명시적 에러 처리 가능성

### 4. 테스트 전략

#### 기존 테스트 유지
- 26개 테스트 케이스 모두 통과 상태 유지
- 매크로 리팩토링 후 기능 동등성 검증

#### 새로운 테스트 추가

**스레드 안전성 테스트:**
```swift
final class ActorContainerTests: XCTestCase {
    func testConcurrentResolve() async throws {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    _ = await Container.shared.resolve(Service.self)
                }
            }
        }
        // 데이터 레이스 없이 완료
    }

    func testActorIsolation() async throws {
        // actor isolation 검증
    }
}
```

**에러 처리 테스트:**
```swift
func testResolveUnregisteredTypeThrows() async throws {
    await XCTAssertThrowsError(
        try await Container.shared.resolve(UnregisteredService.self)
    ) { error in
        XCTAssertTrue(error is ContainerError)
        if case .typeNotRegistered(let type) = error {
            XCTAssertEqual(type, "UnregisteredService")
        }
    }
}

func testResolveOptionalReturnsNilForUnregistered() async throws {
    let result: UnregisteredService? = await Container.shared.resolveOptional()
    XCTAssertNil(result)
}
```

**매크로 코드 생성 테스트:**
```swift
func testBaseScopeMacroCodeGeneration() {
    // 생성된 코드가 기대와 일치하는지 검증
    let assertion: DeclSyntax = """
    @Instance
    var service: MyService!
    """
    // 매크로 확장 결과 검증
}
```

## 마이그레이션 계획

### Phase 1: 매크로 리팩토링 (내부 변경, 사용자 무영향)
1. `BaseScopeMacro` 프로토콜 생성
2. 각 매크로를 새 프로토콜로 이동
3. 기존 매크로 파일 유지 (호환성)
4. 모든 테스트 통과 확인
5. 컴파일러 경고 수정

### Phase 2: Container Actor 변환 (API 호환성 유지)
1. `class Container` → `actor Container`
2. `nonisolated(unsafe)` 제거
3. `NSLock` 제거
4. 기존 테스트 통과 확인
5. 스레드 안전성 테스트 추가

### Phase 3: 에러 처리 시스템 도입 (선택적 API 추가)
1. `ContainerError` 타입 추가
2. throwing API 추가 (`resolve() throws`)
3. 기존 API 유지 (`resolveOptional()`)
4. 문서에 마이그레이션 가이드 추가
5. 에러 처리 테스트 추가

## 하위 호환성

```swift
// 기존 코드는 계속 작동
@Instance
var service: MyService!

// 새로운 에러 처리 방식 (선택적)
let service: MyService = try await Container.resolve()

// 기존 방식도 계속 지원
let service: MyService? = await Container.resolveOptional()
```

## 성능 고려사항

### Actor 오버헤드
- actor 전환은 가볍지만 빈번한 호출 시 고려 필요
- 대부분의 DI 시나리오에서는 무시할 수 있는 수준

### WeakBox 메모리 관리
- weak 참조 해제 후 WeakBox 객체가 storage에 남는 문제
- 주기적 정리 메서드 도입 고려

## 파일 구조 변경

```
Sources/ServiceAttachMacros/
├── ServiceAttachMacro.swift (변경 없음)
├── MacroError.swift (에러 추가 가능)
├── Helper.swift (개선 가능)
└── Macros/
    ├── Base/
    │   └── BaseScopeMacro.swift (신규)
    ├── InstanceMacro.swift (리팩토링)
    ├── SharedMacro.swift (리팩토링)
    ├── WeakMacro.swift (리팩토링 + 버그 수정)
    ├── LazyMacro.swift (리팩토링)
    └── UnregisterMacro.swift (버그 수정)

Sources/ServiceAttach/Containers/
└── Container.swift (class → actor)
```

## 검증清单

- [ ] BaseScopeMacro 프로토콜 구현
- [ ] 모든 매크로가 BaseScopeMacro 준수
- [ ] Container actor 변환
- [ ] ContainerError 타입 구현
- [ ] 모든 기존 테스트 통과
- [ ] 스레드 안전성 테스트 추가 및 통과
- [ ] 에러 처리 테스트 추가 및 통과
- [ ] 컴파일러 경고 모두 해결
- [ ] 문서 업데이트
- [ ] 예제 코드 업데이트

## 참고

- Swift Concurrency: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
- Swift 6 Migration: https://www.swift.org/documentation/concurrency/migration-checklist/
- swift-syntax: https://github.com/swiftlang/swift-syntax
