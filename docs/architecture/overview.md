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

[`Container`](../../Sources/ServiceAttach/Containers/Container.swift)에 정의된 3가지 스코프:

- **transient** - 매번 새 인스턴스
- **shared** - 싱글톤
- **weak** - weak 참조

상세한 내용은 [macro-system.md](macro-system.md)를 확인하세요.
