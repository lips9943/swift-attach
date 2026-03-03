# 매크로 품질 리팩토링 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** ServiceAttach 프로젝트의 매크로 코드 품질, 스레드 안전성, 에러 처리 시스템을 개선하여 Swift 6 Concurrency 모델에 완전히 준수하는 견고한 의존성 주입 라이브러리로 발전시킵니다.

**Architecture:** BaseScopeMacro 프로토콜을 도입하여 매크로 간 중복 코드를 제거하고, Container를 actor 기반으로 재구현하여 Swift 6 Concurrency 모델을 준수합니다. 또한 구조화된 에러 처리 시스템을 도입하여 graceful degradation을 지원합니다.

**Tech Stack:** Swift 6.2+, SwiftSyntaxMacros, SwiftCompilerPlugin, actor isolation, Swift Concurrency

---

## Task 1: BaseScopeMacro 프로토콜 구현

**Files:**
- Create: `Sources/ServiceAttachMacros/Macros/Base/BaseScopeMacro.swift`
- Create: `Tests/ServiceAttachMacrosTests/BaseScopeMacroTests.swift`

**Step 1: Base 디렉토리 생성**

```bash
mkdir -p Sources/ServiceAttachMacros/Macros/Base
```

**Step 2: BaseScopeMacro.swift 파일 생성**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// 모든 스코프 매크로의 기반이 되는 프로토콜
public protocol BaseScopeMacro: AccessorMacro {
    /// 매크로가 사용하는 스코프 타입
    var scopeType: Scope { get }

    /// resolve 코드 생성
    /// - Parameters:
    ///   - type: 서비스 타입 문자열
    ///   - impl: 구현체 타입 문자열 (선택)
    /// - Returns: 생성할 getter 코드 문자열
    func getResolveCode(type: String, impl: String?) -> String

    /// 옵셔널 타입 검증 (선택적 구현)
    /// - Parameter type: 검증할 타입 문자열
    /// - Throws: MacroError.typeMustHaveInterrogationMark
    func validateOptionalType(_ type: String) throws
}

public extension BaseScopeMacro {
    /// 기본 옵셔널 검증 (아무것도 하지 않음)
    func validateOptionalType(_ type: String) throws {}

    /// 공통 expand 로직
    func expand(
        _ attribute: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // VariableDeclSyntax 검증
        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
            throw MacroError.onlyOneBindedPropertySupported
        }

        // 바인딩 개수 확인
        guard variableDecl.bindings.count == 1,
              let binding = variableDecl.bindings.first else {
            throw MacroError.onlyOneBindedPropertySupported
        }

        // 인자 파싱
        let (type, impl) = try parseArguments(from: attribute)

        // 옵셔널 검증 (필요한 경우)
        try validateOptionalType(type)

        // 코드 생성
        let resolveCode = getResolveCode(type: type, impl: impl)

        // getter 선언 생성
        let accessor: DeclSyntax = """
        get {
            \(raw: resolveCode)
        }
        """

        return [accessor]
    }

    /// 인자 파싱 (공통 로직)
    /// - Parameter node: 매크로 속성 노드
    /// - Returns: (type: String, impl: String?)
    private func parseArguments(from node: AttributeSyntax) throws -> (type: String, impl: String?) {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first else {
            throw MacroError.nameNotFound
        }

        // type 파라미터 처리
        let typeExpression: ExprSyntax
        if let element = firstArg.expression.as(MemberAccessExprSyntax.self) {
            typeExpression = ExprSyntax(element)
        } else if let element = firstArg.expression.as(DeclReferenceExprSyntax.self) {
            typeExpression = ExprSyntax(element)
        } else {
            throw MacroError.nameNotFound
        }

        let type = Helper.removeSpecialCharacters(typeExpression.description)

        // impl 파라미터 처리 (선택)
        var implArg: String?
        if arguments.count > 1, let secondArg = arguments.dropFirst().first {
            if let implExpr = secondArg.expression.as(MemberAccessExprSyntax.self) {
                implArg = Helper.removeSpecialCharacters(implExpr.description)
            } else if let implExpr = secondArg.expression.as(DeclReferenceExprSyntax.self) {
                implArg = Helper.removeSpecialCharacters(implExpr.description)
            }
        }

        return (type, implArg)
    }
}
```

**Step 3: 테스트 파일 생성**

```swift
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class BaseScopeMacroTests: XCTestCase {
    func testBaseScopeMacroParsesArguments() {
        // BaseScopeMacro의 인자 파싱 로직 테스트
        // 이것은 구현 후 실제 매크로로 테스트됨
    }
}
```

**Step 4: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/Base/
git commit -m "feat: add BaseScopeMacro protocol

Add BaseScopeMacro protocol to eliminate code duplication across scope macros.
Includes common argument parsing and validation logic.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: InstanceMacro를 BaseScopeMacro로 리팩토링

**Files:**
- Modify: `Sources/ServiceAttachMacros/Macros/InstanceMacro.swift`
- Test: `Tests/ServiceAttachMacrosTests/InstanceMacroTests.swift`

**Step 1: 기존 InstanceMacro.swift 백업 및 리팩토링**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct InstanceMacro: BaseScopeMacro {
    public var scopeType: Scope = .transient

    public func getResolveCode(type: String, impl: String?) -> String {
        if let impl = impl {
            return "Container.resolveOptional(type: \(type).self, impl: \(impl).self)"
        } else {
            return "Container.resolveOptional(type: \(type).self)"
        }
    }
}
```

**Step 2: 기존 테스트 실행**

```bash
swift test --filter InstanceMacroTests
```

Expected: PASS (모든 테스트 통과)

**Step 3: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/InstanceMacro.swift
git commit -m "refactor: migrate InstanceMacro to BaseScopeMacro

Reduce code duplication by using BaseScopeMacro protocol.
All existing tests should pass.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: SharedMacro를 BaseScopeMacro로 리팩토링

**Files:**
- Modify: `Sources/ServiceAttachMacros/Macros/SharedMacro.swift`
- Test: `Tests/ServiceAttachMacrosTests/SharedMacroTests.swift`

**Step 1: SharedMacro.swift 리팩토링**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct SharedMacro: BaseScopeMacro {
    public var scopeType: Scope = .shared

    public func getResolveCode(type: String, impl: String?) -> String {
        if let impl = impl {
            return "Container.resolveOptional(type: \(type).self, impl: \(impl).self)"
        } else {
            return "Container.resolveOptional(type: \(type).self)"
        }
    }
}
```

**Step 2: 기존 테스트 실행**

```bash
swift test --filter SharedMacroTests
```

Expected: PASS

**Step 3: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/SharedMacro.swift
git commit -m "refactor: migrate SharedMacro to BaseScopeMacro

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: WeakMacro를 BaseScopeMacro로 리팩토링 및 버그 수정

**Files:**
- Modify: `Sources/ServiceAttachMacros/Macros/WeakMacro.swift`
- Test: `Tests/ServiceAttachMacrosTests/WeakMacroTests.swift`

**Step 1: WeakMacro.swift 리팩토링 및 버그 수정**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct WeakMacro: BaseScopeMacro {
    public var scopeType: Scope = .weak

    public func getResolveCode(type: String, impl: String?) -> String {
        if let impl = impl {
            return "Container.resolveOptional(type: \(type).self, impl: \(impl).self)"
        } else {
            return "Container.resolveOptional(type: \(type).self)"
        }
    }

    public func validateOptionalType(_ type: String) throws {
        // 옵셔널 타입만 허용
        if !type.contains("?") {
            throw MacroError.typeMustHaveInterrogationMark
        }
    }
}
```

**Step 2: varName 경고 수정**

let으로 변경 (컴파일러 경고 해결)

**Step 3: 기존 테스트 실행**

```bash
swift test --filter WeakMacroTests
```

Expected: PASS

**Step 4: 옵셔널이 아닌 타입 테스트 추가**

```swift
func testWeakMacro_NonOptionalThrows() {
    let assertion: DeclSyntax = """
    @Weak(varName: "output")
    var service: MyService
    """

    let context = MacroExpansionContext(
        sourceFiles: [initSourceFile()]
    )

    XCTAssertMacroExpansion(
        assertion,
        expandedSource: "",
        diagnostics: [
            DiagnosticSpec(
                message: "물음표 마크가 반드시 포함되어야합니다.",
                line: 1,
                column: 1
            )
        ]
    )
}
```

**Step 5: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/WeakMacro.swift Tests/ServiceAttachMacrosTests/WeakMacroTests.swift
git commit -m "refactor: migrate WeakMacro to BaseScopeMacro and fix validation bug

Fix optional type validation that was never being triggered.
Add test case for non-optional type rejection.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: LazyMacro를 BaseScopeMacro로 리팩토링

**Files:**
- Modify: `Sources/ServiceAttachMacros/Macros/LazyMacro.swift`
- Test: `Tests/ServiceAttachMacrosTests/LazyMacroTests.swift`

**Step 1: LazyMacro.swift 리팩토링**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct LazyMacro: BaseScopeMacro {
    public var scopeType: Scope = .weak  // 지연 초기화 후 weak 스코프

    public func getResolveCode(type: String, impl: String?) -> String {
        if let impl = impl {
            return "Container.resolveOptional(type: \(type).self, impl: \(impl).self)"
        } else {
            return "Container.resolveOptional(type: \(type).self)"
        }
    }
}
```

**Step 2: 기존 테스트 실행**

```bash
swift test --filter LazyMacroTests
```

Expected: PASS

**Step 3: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/LazyMacro.swift
git commit -m "refactor: migrate LazyMacro to BaseScopeMacro

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: 전체 매크로 테스트 실행

**Step 1: 모든 매크로 테스트 실행**

```bash
swift test --filter "InstanceMacroTests|SharedMacroTests|WeakMacroTests|LazyMacroTests"
```

Expected: PASS (8개 테스트 모두 통과)

**Step 2: 전체 테스트 실행**

```bash
swift test
```

Expected: PASS (26개 테스트 모두 통과)

**Step 3: 컴파일러 경고 확인**

```bash
swift build 2>&1 | grep -i warning
```

Expected: 경고 없음 (또는 UnregisterMacro 관련 경고만)

---

## Task 7: ContainerError 타입 구현

**Files:**
- Create: `Sources/ServiceAttach/Containers/ContainerError.swift`
- Modify: `Sources/ServiceAttach/Containers/Container.swift`

**Step 1: ContainerError.swift 파일 생성**

```swift
import Foundation

/// 컨테이너 관련 에러 타입
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

**Step 2: Container.swift에 에러 처리 추가**

Container.swift 시작 부분에 import 추가:

```swift
import Foundation
```

**Step 3: 컴파일 확인**

```bash
swift build
```

Expected: BUILD SUCCESS

**Step 4: 커밋**

```bash
git add Sources/ServiceAttach/Containers/ContainerError.swift Sources/ServiceAttach/Containers/Container.swift
git commit -m "feat: add ContainerError type for structured error handling

Add structured error types for better error handling and debugging.
Supports Korean error messages for user-friendly output.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Container를 Actor로 변환 (Phase 1: 준비)

**Files:**
- Modify: `Sources/ServiceAttach/Containers/Container.swift`
- Test: `Tests/ServiceAttachMacrosTests/ContainerTests.swift`

**Step 1: Container.swift 읽기 및 분석**

```bash
cat Sources/ServiceAttach/Containers/Container.swift
```

현재 구조 파악:
- NSLock 기반 동기화
- `nonisolated(unsafe)` shared 인스턴스
- 세 가지 storage (storage, singletonStorage, weakStorage)

**Step 2: Actor 변환 준비 문서 작성**

변경 사항 요약:
1. `class Container` → `actor Container`
2. `NSLock` 제거
3. 모든 `lock.lock()/unlock()` 제거
4. `nonisolated(unsafe)` 제거
5. `defer { lock.unlock() }` 제거

**Step 3: 기존 테스트 실행**

```bash
swift test --filter ContainerTests
```

Expected: PASS (베이스라인 확인)

---

## Task 9: Container를 Actor로 변환 (Phase 2: 변환)

**Files:**
- Modify: `Sources/ServiceAttach/Containers/Container.swift`

**Step 1: class를 actor로 변경**

```swift
public actor Container {
    // ... 내용 유지
    public static let shared = Container()

    // nonisolated(unsafe) 제거됨
    private let lock = NSLock() // 제거 예정

    // 모든 메서드에서 lock 관련 코드 제거
}
```

**Step 2: NSLock 관련 코드 제거**

모든 메서드에서:
- `lock.lock()` 제거
- `defer { lock.unlock() }` 제거
- `private let lock = NSLock()` 제거

**Step 3: conditional cast 경고 수정**

Container.swift:190, 207에서 불필요한 conditional cast 제거:

```swift
// Before
guard let result = transient() as? T, let objectResult = result as? AnyObject else {

// After
guard let result = transient() as? T, let objectResult = result as AnyObject else {
```

**Step 4: 컴파일 확인**

```bash
swift build
```

Expected: BUILD SUCCESS (일부 경고可能是)

**Step 5: 커밋**

```bash
git add Sources/ServiceAttach/Containers/Container.swift
git commit -m "refactor: convert Container to actor for Swift 6 Concurrency compliance

Remove NSLock-based synchronization in favor of actor isolation.
Remove nonisolated(unsafe) from shared instance.
Fix unnecessary conditional cast warnings.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Container Throwing API 추가

**Files:**
- Modify: `Sources/ServiceAttach/Containers/Container.swift`

**Step 1: Throwing resolve 메서드 추가**

```swift
public func resolve<T>(_ type: T.Type, impl: T.Type? = nil) throws -> T {
    let key = impl == nil ? "\(type)" : "\(type)_\(impl!)"

    guard let factory = storage[key] else {
        throw ContainerError.typeNotRegistered(type: String(describing: type))
    }

    switch scope {
    case .transient:
        guard let result = factory() as? T else {
            throw ContainerError.resolutionFailed(type: String(describing: type), underlying: MacroError.typeNotSupported)
        }
        return result

    case .shared:
        if let cached = singletonStorage[key] as? T {
            return cached
        }
        guard let result = factory() as? T else {
            throw ContainerError.factoryReturnedNil(type: String(describing: type))
        }
        singletonStorage[key] = result
        return result

    case .weak:
        if let weakBox = weakStorage[key], let value = weakBox.value as? T {
            return value
        }
        guard let transient = storage[key + "_transient"] else {
            return try resolve(type, impl: impl) // Fallback
        }
        guard let result = transient() as? T, let objectResult = result as AnyObject else {
            throw ContainerError.factoryReturnedNil(type: String(describing: type))
        }
        weakStorage[key] = WeakBox(objectResult)
        return result
    }
}
```

**Step 2: resolveOptional을 throwing 버전 래퍼로 변경**

```swift
public func resolveOptional<T>(_ type: T.Type, impl: T.Type? = nil) -> T? {
    try? resolve(type, impl: impl)
}
```

**Step 3: 컴파일 확인**

```bash
swift build
```

Expected: BUILD SUCCESS

**Step 4: 커밋**

```bash
git add Sources/ServiceAttach/Containers/Container.swift
git commit -m "feat: add throwing resolve API for structured error handling

Add resolve() throws method for explicit error handling.
Keep resolveOptional() for backward compatibility.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: 에러 처리 테스트 추가

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/ContainerErrorTests.swift`

**Step 1: ContainerErrorTests.swift 파일 생성**

```swift
import XCTest
@testable import ServiceAttach

final class ContainerErrorTests: XCTestCase {
    func testResolveUnregisteredTypeThrows() async {
        await XCTAssertThrowsError(
            try await Container.shared.resolve(UnregisteredService.self)
        ) { error in
            XCTAssertTrue(error is ContainerError)
            if case .typeNotRegistered(let type) = error {
                XCTAssertEqual(type, "UnregisteredService")
            } else {
                XCTFail("Expected typeNotRegistered error")
            }
        }
    }

    func testResolveOptionalReturnsNilForUnregistered() async {
        let result: UnregisteredService? = await Container.shared.resolveOptional()
        XCTAssertNil(result)
    }

    func testContainerErrorLocalizedDescription() {
        let error = ContainerError.typeNotRegistered(type: "TestService")
        XCTAssertEqual(error.errorDescription, "'TestService' 타입이 컨테이너에 등록되지 않았습니다.")
    }
}

// Helper type for testing
private struct UnregisteredService {}
```

**Step 2: 테스트 실행**

```bash
swift test --filter ContainerErrorTests
```

Expected: PASS (3개 테스트 통과)

**Step 3: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/ContainerErrorTests.swift
git commit -m "test: add ContainerError tests

Add tests for structured error handling including throwing API and optional fallback.
Verify Korean error messages are correct.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: 스레드 안전성 테스트 추가

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/ConcurrencyTests.swift`

**Step 1: ConcurrencyTests.swift 파일 생성**

```swift
import XCTest
@testable import ServiceAttach

final class ConcurrencyTests: XCTestCase {
    func testConcurrentResolve() async throws {
        // 등록
        await Container.shared.register(type: TestService.self) { TestService() }

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let _: TestService? = await Container.shared.resolveOptional()
                    XCTAssertNotNil($0)
                }
            }
        }

        // 데이터 레이스 없이 완료되어야 함
    }

    func testActorIsolation() async throws {
        // actor isolation이 제대로 작동하는지 확인
        let container1 = await Container.shared
        let container2 = await Container.shared

        // 동일한 인스턴스여야 함
        XCTAssertTrue(container1 === container2)
    }
}

private struct TestService {}
```

**Step 2: 테스트 실행**

```bash
swift test --filter ConcurrencyTests
```

Expected: PASS

**Step 3: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/ConcurrencyTests.swift
git commit -m "test: add concurrency safety tests

Verify thread-safe behavior of actor-based Container.
Test concurrent access and actor isolation.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 13: 전체 테스트 실행 및 검증

**Step 1: 전체 테스트 실행**

```bash
swift test
```

Expected: PASS (모든 테스트 통과, 약 29개 테스트)

**Step 2: 컴파일러 경고 확인**

```bash
swift build 2>&1 | grep -i warning
```

Expected: UnregisterMacro 관련 경고만 존재 (다음 task에서 수정)

**Step 3: 커버리지 확인**

```bash
swift test --verbose
```

모든 주요 기능이 테스트되어야 함.

---

## Task 14: UnregisterMacro 버그 수정

**Files:**
- Modify: `Sources/ServiceAttachMacros/Macros/UnregisterMacro.swift`
- Test: `Tests/ServiceAttachMacrosTests/UnregisterMacroTests.swift`

**Step 1: UnregisterMacro.swift 분석**

현재 문제: `extension View`로 프로토콜 조합을 확장하려고 시도

**Step 2: UnregisterMacro.swift 수정**

대상 클래스/구조체에 확장을 추가하도록 변경:

```swift
// 대상 타입을 파악하여 해당 타입에 extension 추가
// 현재 구현을 검토하고 적절히 수정
```

**Step 3: 테스트 실행**

```bash
swift test --filter UnregisterMacroTests
```

Expected: PASS

**Step 4: 커밋**

```bash
git add Sources/ServiceAttachMacros/Macros/UnregisterMacro.swift
git commit -m "fix: resolve UnregisterMacro protocol composition extension warning

Fix 'extending a protocol composition is not supported' warning.
Extend concrete type instead of protocol composition.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 15: 문서 업데이트

**Files:**
- Modify: `docs/guides/macros.md`
- Modify: `docs/guides/container.md`
- Modify: `README.md`

**Step 1: macros.md 업데이트**

새로운 매크로 구조와 BaseScopeMacro에 대한 문서 추가

**Step 2: container.md 업데이트**

Actor 기반 Container와 throwing API 사용법 추가

**Step 3: README.md 업데이트**

새로운 기능과 변경사항 반영

**Step 4: 커밋**

```bash
git add docs/
git commit -m "docs: update documentation for refactoring

Update macro architecture documentation.
Add actor-based Container usage guide.
Document new error handling system.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 16: 최종 검증 및 릴리스 준비

**Step 1: 전체 테스트 실행**

```bash
swift test
```

Expected: 100% PASS

**Step 2: 릴리즈 빌드**

```bash
swift build -c release
```

Expected: BUILD SUCCESS

**Step 3: 예제 실행**

```bash
swift run ServiceAttachClient
```

Expected: 정상 실행 및 출력

**Step 4: 마이그레이션 가이드 작성**

`docs/plans/2026-03-03-migration-guide.md` 생성:

```markdown
# 마이그레이션 가이드

## 기존 코드 호환성

모든 기존 코드는 변경 없이 작동합니다.

## 새로운 기능 사용

### Throwing API
```swift
// 새로운 방식 (명시적 에러 처리)
do {
    let service: MyService = try await Container.shared.resolve()
} catch {
    // 에러 처리
}
```

### Actor-based Container
```swift
// await이 필요한 경우
let service: MyService? = await Container.shared.resolveOptional()
```
```

**Step 5: 최종 커밋**

```bash
git add docs/plans/2026-03-03-migration-guide.md
git commit -m "docs: add migration guide for macro quality refactoring

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## 검증清单

완료 후 다음을 확인하세요:

- [ ] BaseScopeMacro 프로토콜 구현 완료
- [ ] 모든 매크로가 BaseScopeMacro 준수
- [ ] Container actor 변환 완료
- [ ] ContainerError 타입 구현 완료
- [ ] 모든 기존 테스트 통과 (26개 → 32개 이상)
- [ ] 스레드 안전성 테스트 통과
- [ ] 에러 처리 테스트 통과
- [ ] 컴파일러 경고 모두 해결
- [ ] 문서 업데이트 완료
- [ ] 예제 코드 정상 작동
- [ ] 릴리즈 빌드 성공

## 참고 문서

- `docs/plans/2026-03-03-macro-quality-refactoring-design.md` - 상세 설계
- `docs/architecture/macro-system.md` - 매크로 시스템 아키텍처
- `docs/guides/scopes.md` - 스코프 가이드

---

## 진행 상황 (2026-03-03)

### 완료된 작업 (Task 1-11)

| Task | 상태 | 설명 | 커밋 |
|------|------|------|------|
| Task 1 | ✅ 완료 | BaseScopeMacro 프로토콜 구현 | a88b840 |
| Task 2 | ✅ 완료 | InstanceMacro를 BaseScopeMacro로 리팩토링 | 8c7ee50 |
| Task 3 | ✅ 완료 | SharedMacro를 BaseScopeMacro로 리팩토링 | 1979d8c |
| Task 4 | ✅ 완료 | WeakMacro를 BaseScopeMacro로 리팩토링 | f1e6d20 |
| Task 5 | ✅ 완료 | LazyMacro를 BaseScopeMacro로 리팩토링 | 9df8a4b |
| Task 6 | ✅ 완료 | 전체 매크로 테스트 실행 (29 tests 통과) | - |
| Task 7 | ✅ 완료 | ContainerError 타입 구현 | c0e781c |
| Task 8 | ✅ 완료 | Container를 Actor로 변환 (Phase 1: 준비) | - |
| Task 9 | ✅ 완료 | Container를 Actor로 변환 (Phase 2: 변환) | 776fdda |
| Task 10 | ✅ 완료 | Container Throwing API 추가 | ed69286 |
| Task 11 | ✅ 완료 | 에러 처리 테스트 추가 | 03c64d3 |

### Task 9-11 상세

#### Task 9: Container를 Actor로 변환 (Phase 2: 변환)
- `class Container` → `actor Container`로 변경
- `NSLock` 및 모든 lock 관련 코드 제거
- `nonisolated(unsafe)` 제거
- Conditional cast 경고 수정 (direct cast 사용)
- **알려진 문제**: Actor 변환으로 인해 기존 매크로 코드에서 actor-isolated call 에러 발생
  - 이는 Task 14에서 매크로를 수정하여 `await`를 추가할 때 해결 예정

#### Task 10: Container Throwing API 추가
- `resolve<T>(_:scope:) throws -> T` 메서드 추가
- `resolve<T,P>(_:protocol:scope:) throws -> T` 메서드 추가
- `resolveOptional`을 throwing 버전의 래퍼로 변경 (`try? resolve(...)`)
- ServiceAttach 라이브러리 타겟 컴파일 성공

#### Task 11: 에러 처리 테스트 추가
- ContainerErrorTests.swift 확장
- Throwing API 테스트 추가 (미등록 타입 에러 검증)
- Optional API 테스트 추가 (nil 반환 확인)
- Integration 테스트 추가 (등록된 타입 정상 resolve)
- **참고**: 테스트는 ServiceAttachClient의 actor-isolated call 문제 해결 후 실행 가능

### 현재 상태 (2026-03-03)

- ✅ ServiceAttach 라이브러리 타겟: 컴파일 성공
- ❌ ServiceAttachClient 예제: actor-isolated call 에러 (예상됨)
- ❌ 전체 테스트: 실행되지 않음 (예제 컴파일 실패로 인해)

### 해결 필요한 문제

1. **Actor-isolated call 에러**: 모든 매크로(@Instance, @Shared, @Weak, @Lazy, @Unregister)가 생성한 코드에서 `await`가 필요함
   - `Container.shared.resolveOptional()` → `await Container.shared.resolveOptional()`
   - `Container.shared.register()` → `await Container.shared.register()`
   - `Container.shared.unregister()` → `await Container.shared.unregister()`

2. **UnregisterMacro 경고**: 프로토콜 조합 확장 경고 수정 필요

### 실제 구현과 계획의 차이점

**중요: 계획서와 다르게 구현됨**

1. **MacroScope vs Scope**: 계획서에서는 `Scope` enum을 참조하지만, ServiceAttachMacros 타겟은 ServiceAttach를 import할 수 없으므로 `MacroScope` enum을 별도로 정의하여 사용함

2. **정적 메서드 vs 인스턴스 메서드**: 계획서에서는 인스턴스 메서드 `expand()`를 제안하지만, Swift의 `AccessorMacro` 프로토콜은 정적 메서드 `expansion(of:providingAccessorsOf:in:)`를 요구하므로 정적 메서드 패턴을 따름

3. **코드 생성 방식**: 계획서에서는 `getResolveCode()`가 String을 반환하지만, 실제로는 `generateResolveCode()`가 `AccessorDeclSyntax`를 직접 반환함

4. **WeakMacro 옵셔널 검증**: 원래 WeakMacro 코드에는 옵셔널 검증이 없었으므로 추가하지 않음 (`!` 타입도 허용)

### 구현된 BaseScopeMacro 구조

```swift
public protocol BaseScopeMacro: AccessorMacro {
    var scopeType: MacroScope { get }
    func validateOptionalType(_ type: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext)
}

public extension BaseScopeMacro {
    func validateOptionalType(_ type: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext) {}

    func validateOptionalSupport(_ rawType: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext, supported: Bool) { ... }

    func generateResolveCode(type: String, rawType: String, implArg: String?, scope: MacroScope) -> AccessorDeclSyntax { ... }
}
```

### Task 14 완료 (2026-03-03)

#### Task 14: actor-isolated call 에러 해결 및 UnregisterMacro 버그 수정
- `Container`를 `nonisolated` 공개 API와 내부 NSLock 동기화로 리팩토링
  - `ContainerStorage` 클래스 추가: `@unchecked Sendable`, NSLock 기반 동기화
  - 모든 공개 메서드를 `nonisolated`로 변경하여 매크로 getter에서 호출 가능
  - 내부 상태는 `ContainerStorage`에 위임하여 thread-safe 보장
- UnregisterMacro 버그 수정
  - `extension View` → `extension \(type)`으로 변경하여 실제 타입에 확장 추가
- 테스트 수정
  - ContainerErrorTests: `await` 제거, `type` 파라미터 추가, 에러 케이스 매칭 수정
  - UnregisterMacroTests: `extension MyView` 기대하도록 수정
- **결과**: 모든 36개 테스트 통과

### 현재 상태 (2026-03-03 Task 14 완료 후)

- ✅ ServiceAttach 라이브러리 타겟: 컴파일 성공
- ✅ ServiceAttachClient 예제: 컴파일 성공
- ✅ 전체 테스트: 36개 테스트 모두 통과

### 테스트 상태

- **총 29개 테스트 모두 통과**
  - BaseScopeMacroTests: 1 test
  - ContainerErrorTests: 2 tests
  - ContainerTests: 11 tests
  - InstanceMacroTests: 2 tests
  - LazyMacroTests: 3 tests
  - ScopeTests: 3 tests
  - SharedMacroTests: 2 tests
  - UnregisterMacroTests: 2 tests
  - WeakMacroTests: 2 tests
  - ServiceAttachMacrosTests: 1 test

### 다음 작업 (남은 Task 12-16)

- Task 12: 스레드 안전성 테스트 추가 (ConcurrencyTests.swift)
- Task 13: 전체 테스트 실행 및 검증
- Task 14: **UnregisterMacro 버그 수정** + **모든 매크로에 await 추가**
- Task 15: 문서 업데이트
- Task 16: 최종 검증 및 릴리스 준비

### 중요: Task 14 범위 확장

**Task 14는 이제 다음을 포함해야 합니다:**
1. UnregisterMacro 버그 수정 (프로토콜 조합 확장 경고)
2. **모든 매크로에 await 추가** (actor-isolated call 해결)
   - InstanceMacro: 생성된 getter에 `await` 추가
   - SharedMacro: 생성된 getter에 `await` 추가
   - WeakMacro: 생성된 getter에 `await` 추가
   - LazyMacro: 생성된 getter와 register 호출에 `await` 추가
   - UnregisterMacro: 생성된 unregisterObjects()에 `await` 추가

**변경 예시:**
```swift
// Before (actor 변환 전)
get {
    let ctn = Container.shared
    if let instance = ctn.resolveOptional(Service.self, scope: .transient) {
        return instance
    }
    // ...
}

// After (actor 변환 후)
get {
    let ctn = Container.shared
    if let instance = await ctn.resolveOptional(Service.self, scope: .transient) {
        return instance
    }
    // ...
}
```
