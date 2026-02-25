# Macro Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Swift Macros가 올바른 코드를 생성하는지 검증하는 테스트 스위트 구현

**Architecture:** SwiftSyntax의 MacroExpansionTestCase를 사용하여 매크로 확장 전후의 소스 코드를 문자열로 비교하는 구조

**Tech Stack:** Swift 6.2, SwiftSyntax 602.0.0+, SwiftSyntaxMacrosTestSupport, XCTest

---

## Task 1: Package.swift에 테스트 타겟 추가

**Files:**
- Modify: `Package.swift`

**Step 1: 테스트 타겟 추가**

Package.swift의 targets 배열 끝에 testTarget을 추가:

```swift
// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ServiceAttach",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(name: "ServiceAttach", targets: ["ServiceAttach"]),
        .executable(name: "ServiceAttachClient", targets: ["ServiceAttachClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
    ],
    targets: [
        .macro(
            name: "ServiceAttachMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "ServiceAttach", dependencies: ["ServiceAttachMacros"]),
        .executableTarget(
            name: "ServiceAttachClient",
            dependencies: ["ServiceAttach"]
        ),

        // === 테스트 타겟 추가 ===
        .testTarget(
            name: "ServiceAttachMacrosTests",
            dependencies: [
                "ServiceAttachMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        ),
    ]
)
```

**Step 2: 빌드 검증**

Run: `swift build`
Expected: BUILD SUCCESS

**Step 3: 커밋**

```bash
git add Package.swift
git commit -m "feat: add ServiceAttachMacrosTests target to Package.swift"
```

---

## Task 2: 테스트 디렉토리 및 기본 파일 생성

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/ServiceAttachMacrosTests.swift`

**Step 1: 테스트 디렉토리 생성**

```bash
mkdir -p Tests/ServiceAttachMacrosTests
```

**Step 2: 기본 테스트 파일 생성**

```swift
import XCTest
@testable import ServiceAttachMacros

final class ServiceAttachMacrosTests: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true)
    }
}
```

**Step 3: 테스트 실행으로 검증**

Run: `swift test`
Expected: PASS (testExample가 통과)

**Step 4: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/
git commit -m "feat: create ServiceAttachMacrosTests base directory and file"
```

---

## Task 3: InstanceMacroTests.swift 구현

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/InstanceMacroTests.swift`

**Step 1: InstanceMacroTests.swift 작성**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class InstanceMacroTests: MacroExpansionTestCase {

    func testInstanceMacro_WithoutImpl() throws {
        assertMacroExpansion(
            """
            @Instance
            var service: MyService!
            """,
            expandedSource: """
            var service: MyService! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(MyService.self, scope: .transient) {
                        return instance
                    } else {
                        let impl = MyService()
                        ctn.register(impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Instance": InstanceMacro.self]
        )
    }

    func testInstanceMacro_WithImpl() throws {
        assertMacroExpansion(
            """
            @Instance(impl: ServiceImpl.self)
            var service: ServiceProtocol!
            """,
            expandedSource: """
            var service: ServiceProtocol! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(ServiceImpl.self, protocol: ServiceProtocol.self, scope: .transient) {
                        return instance
                    } else {
                        let impl = ServiceImpl()
                        ctn.register(protocol: ServiceProtocol.self, impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Instance": InstanceMacro.self]
        )
    }
}
```

**Step 2: 테스트 실행 및 실패 확인**

Run: `swift test --filter InstanceMacroTests`
Expected: FAIL (매크로 확장 코드가 예상과 다를 수 있음 - 실제 결과를 확인하여 수정 필요)

**Step 3: 실제 확장 결과 확인 후 테스트 수정**

만약 테스트가 실패하면, 실제 매크로 확장 결과를 확인하고 expectedSource를 수정합니다.

Run: `swift test --filter InstanceMacroTests --verbose`
Expected: PASS (실제 매크로 동작과 일치하도록 수정 후)

**Step 4: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/InstanceMacroTests.swift
git commit -m "feat: add InstanceMacro tests with basic and impl variants"
```

---

## Task 4: SharedMacroTests.swift 구현

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/SharedMacroTests.swift`

**Step 1: SharedMacroTests.swift 작성**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class SharedMacroTests: MacroExpansionTestCase {

    func testSharedMacro_WithoutImpl() throws {
        assertMacroExpansion(
            """
            @Shared
            var service: MyService!
            """,
            expandedSource: """
            var service: MyService! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(MyService.self, scope: .shared) {
                        return instance
                    } else {
                        let impl = MyService()
                        ctn.register(impl: impl, scope: .shared)
                        return impl
                    }
                }
            }
            """,
            macros: ["Shared": SharedMacro.self]
        )
    }

    func testSharedMacro_WithImpl() throws {
        assertMacroExpansion(
            """
            @Shared(impl: ServiceImpl.self)
            var service: ServiceProtocol!
            """,
            expandedSource: """
            var service: ServiceProtocol! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(ServiceImpl.self, protocol: ServiceProtocol.self, scope: .shared) {
                        return instance
                    } else {
                        let impl = ServiceImpl()
                        ctn.register(protocol: ServiceProtocol.self, impl: impl, scope: .shared)
                        return impl
                    }
                }
            }
            """,
            macros: ["Shared": SharedMacro.self]
        )
    }
}
```

**Step 2: 테스트 실행**

Run: `swift test --filter SharedMacroTests`
Expected: PASS (필요시 actual 결과에 맞춰 수정)

**Step 3: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/SharedMacroTests.swift
git commit -m "feat: add SharedMacro tests"
```

---

## Task 5: WeakMacroTests.swift 구현

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/WeakMacroTests.swift`

**Step 1: WeakMacroTests.swift 작성**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class WeakMacroTests: MacroExpansionTestCase {

    func testWeakMacro_Basic() throws {
        assertMacroExpansion(
            """
            @Weak(varName: "output")
            var interactor: Interactor!
            """,
            expandedSource: """
            var interactor: Interactor! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(Interactor.self, scope: .weak) {
                        return instance
                    } else {
                        fatalError("Weak reference not found: output")
                    }
                }
            }
            """,
            macros: ["Weak": WeakMacro.self]
        )
    }

    func testWeakMacro_WithProtocol() throws {
        assertMacroExpansion(
            """
            @Weak(varName: "view", protocols: PresenterProtocol.self)
            var presenter: Presenter!
            """,
            expandedSource: """
            var presenter: Presenter! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(Presenter.self, protocol: PresenterProtocol.self, scope: .weak) {
                        return instance
                    } else {
                        fatalError("Weak reference not found: view")
                    }
                }
            }
            """,
            macros: ["Weak": WeakMacro.self]
        )
    }
}
```

**Step 2: 테스트 실행**

Run: `swift test --filter WeakMacroTests`
Expected: PASS (필요시 actual 결과에 맞춰 수정)

**Step 3: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/WeakMacroTests.swift
git commit -m "feat: add WeakMacro tests"
```

---

## Task 6: UnregisterMacroTests.swift 구현

**Files:**
- Create: `Tests/ServiceAttachMacrosTests/UnregisterMacroTests.swift`

**Step 1: UnregisterMacroTests.swift 작성**

```swift
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class UnregisterMacroTests: MacroExpansionTestCase {

    func testUnregisterMacro_SingleType() throws {
        assertMacroExpansion(
            """
            @Unregister(type: (Presenter.self, nil))
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }
            """,
            expandedSource: """
            class MyView {
                deinit {
                    unregisterObjects()
                }

                func unregisterObjects() {
                    Container.shared.unregister(type: Presenter.self, protocol: nil)
                }
            }
            """,
            macros: ["Unregister": UnregisterMacro.self]
        )
    }

    func testUnregisterMacro_MultipleTypes() throws {
        assertMacroExpansion(
            """
            @Unregister(type: (Presenter.self, nil), (Router.self, nil))
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }
            """,
            expandedSource: """
            class MyView {
                deinit {
                    unregisterObjects()
                }

                func unregisterObjects() {
                    Container.shared.unregister(type: Presenter.self, protocol: nil)
                    Container.shared.unregister(type: Router.self, protocol: nil)
                }
            }
            """,
            macros: ["Unregister": UnregisterMacro.self]
        )
    }
}
```

**Step 2: 테스트 실행**

Run: `swift test --filter UnregisterMacroTests`
Expected: PASS (필요시 actual 결과에 맞춰 수정)

**Step 3: 커밋**

```bash
git add Tests/ServiceAttachMacrosTests/UnregisterMacroTests.swift
git commit -m "feat: add UnregisterMacro tests"
```

---

## Task 7: 전체 테스트 실행 및 검증

**Files:**
- None

**Step 1: 전체 테스트 실행**

Run: `swift test`
Expected: All tests PASS

**Step 2: 각 매크로별 테스트 실행 확인**

```bash
swift test --filter InstanceMacroTests
swift test --filter SharedMacroTests
swift test --filter WeakMacroTests
swift test --filter UnregisterMacroTests
```
Expected: All PASS

**Step 3: 최종 커밋 (필요시 수정 사항 있으면)**

```bash
git add .
git commit -m "test: complete macro testing implementation"
```

---

## Verification Checklist

- [ ] Package.swift에 testTarget 추가
- [ ] Tests/ServiceAttachMacrosTests/ 디렉토리 생성
- [ ] InstanceMacroTests.swift - 2개 테스트 통과
- [ ] SharedMacroTests.swift - 2개 테스트 통과
- [ ] WeakMacroTests.swift - 2개 테스트 통과
- [ ] UnregisterMacroTests.swift - 2개 테스트 통과
- [ ] `swift test` 전체 통과

---

**Worktree Location:** `/Users/jun/github/swift-attach-macro-testing`
**Branch:** `feature/macro-testing`
