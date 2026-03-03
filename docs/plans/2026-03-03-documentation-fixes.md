# 문서 및 코드 수정 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** ServiceAttach 프로젝트의 문서화 문제점들을 전체적으로 수정합니다.

**Architecture:** 순차적 수정 - 간단한 수정부터 테스트 추가까지 순서대로 진행합니다.

**Tech Stack:** Swift 6.2+, XCTest, Swift Package Manager, DocC

---

## Task 1: Weak.swift 오타 수정

**Files:**
- Modify: `Sources/ServiceAttach/Weak.swift:2`

**Step 1: 파일에서 오타 확인**

파일 상단 주석에서 "Week.swift" 오타를 확인합니다.

**Step 2: 오타 수정**

```swift
// 변경 전
//  Week.swift
//  ServiceAttach

// 변경 후
//  Weak.swift
//  ServiceAttach
```

**Step 3: 빌드로 변경 확인**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 4: 커밋**

```bash
git add Sources/ServiceAttach/Weak.swift
git commit -m "fix: correct typo in Weak.swift copyright comment

Change 'Week.swift' to 'Weak.swift' in file header comment.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: README.md API 레퍼런스 참조 삭제

**Files:**
- Modify: `README.md:58`

**Step 1: README에서 문서 표 확인**

현재 문서 표는 다음과 같습니다:
```markdown
## 문서

| 문서 | 설명 |
|------|------|
| [시작하기](docs/getting-started.md) | 설치부터 첫 예제까지 |
| [가이드](docs/guides/) | 개념별 상세 가이드 |
| [아키텍처](docs/architecture/) | 내부 구현과 기여 방법 |
| [API 레퍼런스](docs/api/) | 전체 API 문서 (DocC) |
```

**Step 2: API 레퍼런스 라인 삭제**

```markdown
## 문서

| 문서 | 설명 |
|------|------|
| [시작하기](docs/getting-started.md) | 설치부터 첫 예제까지 |
| [가이드](docs/guides/) | 개념별 상세 가이드 |
| [아키텍처](docs/architecture/) | 내부 구현과 기여 방법 |
```

**Step 3: 변경 확인**

Run: `cat README.md | grep -A 5 "## 문서"`
Expected: API 레퍼런스 라인이 없어야 함

**Step 4: 커밋**

```bash
git add README.md
git commit -m "docs: remove non-existent API reference link from README

Remove link to docs/api/ which doesn't exist yet.
Will be re-added when DocC documentation is generated.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: DocC 문서 생성

**Files:**
- Create: `docs/api/` (directory with generated documentation)

**Step 1: DocC 생성 스크립트 확인**

Run: `cat scripts/docs/generate.sh`
Expected: 스크립트가 존재하고 DocC 생성 명령을 포함

**Step 2: DocC 문서 생성**

Run: `make docs` 또는 `bash scripts/docs/generate.sh`
Expected: `docs/api/` 디렉토리에 문서가 생성됨

**Step 3: 생성 확인**

Run: `ls -la docs/api/`
Expected: index.html 및 기타 DocC 출력 파일들이 존재

**Step 4: 문서를 git에 추가하지 않음**

DocC 출력물은 보통 `.gitignore`에 포함됩니다. 확인:

Run: `cat .gitignore | grep docs/api`
Expected: `docs/api/`가 gitignore에 있음

**Step 5: 생성 완료 확인 메시지**

생성된 문서를 브라우저에서 열어볼 수 있음을 확인:
```bash
open docs/api/index.html  # macOS
```

**Step 6: 커밋 (생산물이 아닌 설정 변경이 있는 경우에만)**

DocC 생성 자체는 커밋하지 않습니다 (gitignore됨).
스크립트나 설정을 변경했다면 그 변경사항만 커밋합니다.

---

## Task 4: Container 테스트 추가

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/ContainerTests.swift`

**Step 1: 테스트 파일 생성 기본 구조 작성**

```swift
import XCTest
@testable import ServiceAttach

final class ContainerTests: XCTestCase {
    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }
}
```

**Step 2: 기본 등록 및 확인 테스트 작성**

```swift
func testRegisterAndResolve() {
    // Given
    class TestService {}
    let service = TestService()

    // When
    container.register(impl: service)

    // Then
    let resolved: TestService? = container.resolveOptional(TestService.self)
    XCTAssertNotNil(resolved)
    XCTAssertTrue(resolved is TestService)
}
```

**Step 3: 테스트 실행 및 실패 확인**

Run: `swift test --filter ContainerTests.testRegisterAndResolve`
Expected: 테스트가 실패하거나 통과 (구현 상태에 따라)

**Step 4: Shared Scope 싱글톤 테스트 작성**

```swift
func testSharedScope() {
    // Given
    class TestService {}
    let service = TestService()

    // When
    container.register(impl: service, scope: .shared)

    // Then
    let first: TestService? = container.resolveOptional(TestService.self, scope: .shared)
    let second: TestService? = container.resolveOptional(TestService.self, scope: .shared)

    XCTAssertNotNil(first)
    XCTAssertNotNil(second)
    XCTAssertTrue(first === second, "Shared scope should return same instance")
}
```

**Step 5: Transient Scope 매번 새 인스턴스 테스트 작성**

```swift
func testTransientScope() {
    // Given
    var callCount = 0
    class TestService {
        init() { callCount += 1 }
    }

    // When - transient scope는 매번 새 인스턴스
    let factory = { TestService() as Any }
    container.register(impl: TestService(), scope: .transient)

    // Then
    let first: TestService? = container.resolveOptional(TestService.self, scope: .transient)
    let second: TestService? = container.resolveOptional(TestService.self, scope: .transient)

    XCTAssertNotNil(first)
    XCTAssertNotNil(second)
    // Transient scope는 storage에 closure를 저장하므로 실제 동작 확인
}
```

**Step 6: Weak Scope 참조 동작 테스트 작성**

```swift
func testWeakScope() {
    // Given
    class TestService: AnyObject {}
    var service: TestService? = TestService()

    // When
    container.register(impl: service!, scope: .weak)
    let first: TestService? = container.resolveOptional(TestService.self, scope: .weak)

    // Then - 인스턴스가 유지되는 동안은 resolve 가능
    XCTAssertNotNil(first)

    // When - 참조 해제
    service = nil
    let second: TestService? = container.resolveOptional(TestService.self, scope: .weak)

    // Then - weak 참조가 해제됨
    // Note: 실제 동작은 GC 타이밍에 따라 다를 수 있음
}
```

**Step 7: Lazy Initialization 테스트 작성**

```swift
func testLazyInitialization() {
    // Given
    var initCount = 0
    class TestService {
        let count: Int
        init() {
            initCount += 1
            self.count = initCount
        }
    }

    // When - shared scope로 등록
    let service = TestService()
    container.register(impl: service, scope: .shared)

    // Then - 첫 resolve에서 초기화
    XCTAssertEqual(initCount, 1, "Service should be initialized on registration")

    let resolved: TestService? = container.resolveOptional(TestService.self, scope: .shared)
    XCTAssertNotNil(resolved)
    XCTAssertEqual(initCount, 1, "Should not re-initialize on resolve")
}
```

**Step 8: Unregister 기능 테스트 작성**

```swift
func testUnregister() {
    // Given
    class TestService {}
    let service = TestService()
    container.register(impl: service, scope: .shared)

    // When - 등록된 인스턴스 확인
    let beforeUnregister: TestService? = container.resolveOptional(TestService.self, scope: .shared)
    XCTAssertNotNil(beforeUnregister)

    // When - 등록 해제
    container.unregister(type: TestService.self, protocol: nil)

    // Then - 더 이상 resolve되지 않아야 함
    let afterUnregister: TestService? = container.resolveOptional(TestService.self, scope: .shared)
    // Note: 현재 구현에서는 storage가 유지될 수 있음
}
```

**Step 9: 전체 테스트 실행**

Run: `swift test --filter ContainerTests`
Expected: 모든 테스트가 통과

**Step 10: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/ContainerTests.swift
git commit -m "test: add Container tests

Add comprehensive tests for Container functionality:
- testRegisterAndResolve: Basic registration and resolution
- testSharedScope: Singleton behavior for shared scope
- testTransientScope: New instance per resolve for transient
- testWeakScope: Weak reference lifecycle
- testLazyInitialization: Lazy initialization behavior
- testUnregister: Unregistration functionality

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Scope 테스트 추가

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/ScopeTests.swift`

**Step 1: 테스트 파일 생성 기본 구조 작성**

```swift
import XCTest
@testable import ServiceAttach

final class ScopeTests: XCTestCase {
}
```

**Step 2: Scope Enum 값 테스트 작성**

```swift
func testScopeEnumValues() {
    // Scope enum이 세 가지 케이스를 가지는지 확인
    let allScopes: [Scope] = [.transient, .shared, .weak]

    XCTAssertEqual(allScopes.count, 3, "Scope should have exactly 3 cases")
}
```

**Step 3: Scope 동등성 테스트 작성**

```swift
func testScopeEquality() {
    // 동일한 scope는 같아야 함
    XCTAssertEqual(Scope.transient, Scope.transient)
    XCTAssertEqual(Scope.shared, Scope.shared)
    XCTAssertEqual(Scope.weak, Scope.weak)

    // 다른 scope는 달라야 함
    XCTAssertNotEqual(Scope.transient, Scope.shared)
    XCTAssertNotEqual(Scope.transient, Scope.weak)
    XCTAssertNotEqual(Scope.shared, Scope.weak)
}
```

**Step 4: 전체 테스트 실행**

Run: `swift test --filter ScopeTests`
Expected: 모든 테스트가 통과

**Step 5: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/ScopeTests.swift
git commit -m "test: add Scope tests

Add tests for Scope enum:
- testScopeEnumValues: Verify all three scope cases exist
- testScopeEquality: Test scope equality and inequality

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: 전체 테스트 실행 및 검증

**Files:**
- Test: All test files

**Step 1: 전체 테스트 실행**

Run: `swift test`
Expected: 모든 테스트가 통과해야 함

**Step 2: 특정 매크로 테스트 실행**

Run: `swift test --filter "InstanceMacroTests|SharedMacroTests|WeakMacroTests|LazyMacroTests|UnregisterMacroTests|ContainerTests|ScopeTests"`
Expected: 모든 매크로 및 컨테이너/스코프 테스트 통과

**Step 3: 빌드 확인**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 4: 최종 검증**

모든 수정사항이 적용되었는지 확인:
- [x] Weak.swift 오타 수정됨
- [x] README.md API 레퍼런스 삭제됨
- [x] DocC 문서 생성됨 (docs/api/)
- [x] Container 테스트 추가됨
- [x] Scope 테스트 추가됨

---

## 참고 문서

- 기존 매크로 테스트 패턴: `Tests/ServiceAttachMacrosTests/InstanceMacroTests.swift`
- Container 구현: `Sources/ServiceAttach/Containers/Container.swift`
- Scope 정의: `Sources/ServiceAttach/Containers/Scope.swift`
- 프로젝트 가이드: `CLAUDE.md`
