# Macro Testing Design

**Date:** 2025-02-25
**Status:** Approved

## Overview

ServiceAttach 매크로의 확장 결과를 검증하기 위해 SwiftSyntax의 표준 패턴(`MacroExpansionTestCase`)을 사용하는 테스트 구조를 설계합니다.

## Goals

- 매크로가 올바른 Swift 코드를 생성하는지 검증
- 핵심 매크로(@Instance, @Shared, @Weak, @Unregister) 테스트 커버리지 확보
- Swift 팀의 표준 패턴을 따라 유지보수성 확보

## Test Structure

```
Tests/
└── ServiceAttachMacrosTests/
    ├── ServiceAttachMacrosTests.swift      # 테스트 진입점
    ├── InstanceMacroTests.swift             # @Instance 테스트
    ├── SharedMacroTests.swift               # @Shared 테스트
    ├── WeakMacroTests.swift                 # @Weak 테스트
    └── UnregisterMacroTests.swift           # @Unregister 테스트
```

## Test Format

각 테스트는 `MacroExpansionTestCase.assertMacroExpansion()`을 사용하여 매크로 확장 전후의 코드를 비교합니다:

```swift
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
```

## Test Coverage

### @Instance Macro
- Basic usage: `@Instance var x: MyType!`
- With implementation: `@Instance(impl: Impl.self) var x: Protocol!`

### @Shared Macro
- Basic usage: `@Shared var x: MyType!`
- With implementation: `@Shared(impl: Impl.self) var x: Protocol!`

### @Weak Macro
- Basic usage: `@Weak(varName: "name") var x: MyType!`
- With protocol: `@Weak(varName: "name", protocol: Proto.self) var x: MyType!`

### @Unregister Macro
- Single type: `@Unregister(type: (A.self, nil))`
- Multiple types: `@Unregister(type: (A.self, nil), (B.self, nil))`

**Note:** Error cases (optional types, invalid types) are excluded as they are already handled in `MacroError.swift`.

## Package.swift Changes

Add test target:

```swift
.testTarget(
    name: "ServiceAttachMacrosTests",
    dependencies: [
        "ServiceAttachMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
    ]
)
```

## Implementation Steps

1. Modify Package.swift to add test target
2. Create Tests/ServiceAttachMacrosTests/ directory
3. Create ServiceAttachMacrosTests.swift (base file)
4. Create InstanceMacroTests.swift (2 test cases)
5. Create SharedMacroTests.swift (2 test cases)
6. Create WeakMacroTests.swift (2 test cases)
7. Create UnregisterMacroTests.swift (2 test cases)
8. Run `swift test` to verify

## Verification

```bash
# Run all tests
swift test

# Run specific test
swift test --filter InstanceMacroTests

# Run in Xcode
# Open test file and press Cmd+U
```
