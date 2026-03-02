# 문서 및 코드 수정 디자인 문서

**날짜:** 2026-03-03
**상태:** 승인됨

## 개요

ServiceAttach 프로젝트의 문서화 문제점들을 전체적으로 수정합니다.

## 수정 항목

| 순서 | 항목 | 파일 | 변경 내용 |
|------|------|------|-----------|
| 1 | 오타 수정 | `Sources/ServiceAttach/Weak.swift:2` | "Week.swift" → "Weak.swift" |
| 2 | README 수정 | `README.md` | API 레퍼런스 라인 삭제 |
| 3 | DocC 생성 | `docs/api/` | `make docs` 실행 |
| 4 | Container 테스트 | `Tests/ServiceAttachMacrosTests/ContainerTests.swift` | 새 파일 생성 |
| 5 | Scope 테스트 | `Tests/ServiceAttachMacrosTests/ScopeTests.swift` | 새 파일 생성 |

## 상세 설계

### 1. 오타 수정

```swift
// 변경 전
//  Week.swift

// 변경 후
//  Weak.swift
```

### 2. README 수정

API 레퍼런스 라인을 표에서 삭제:

```markdown
| [API 레퍼런스](docs/api/) | 전체 API 문서 (DocC) |
```

### 3. DocC 문서 생성

- 명령: `make docs`
- 스크립트: `scripts/docs/generate.sh`
- 출력: `docs/api/` 디렉토리

### 4. Container 테스트

**파일:** `Tests/ServiceAttachMacrosTests/ContainerTests.swift`

테스트 항목:
- `testRegisterAndResolve` - 등록 및 확인 기본 기능
- `testSharedScope` - shared scope 싱글톤 동작
- `testTransientScope` - transient scope 매번 새 인스턴스
- `testWeakScope` - weak scope 참조 동작
- `testLazyInitialization` - 지연 초기화 동작
- `testUnregister` - 등록 해제 기능

### 5. Scope 테스트

**파일:** `Tests/ServiceAttachMacrosTests/ScopeTests.swift`

테스트 항목:
- `testScopeEnumValues` - Scope enum 값 확인
- `testScopeEquality` - Scope 동등성 비교
- `testScopeDescription` - Scope 설명 문자열 확인

## 접근 방식

순차적 수정: 모든 항목을 순서대로 진행하여 단일 PR로 완료합니다.

## 테스트 패턴

기존 매크로 테스트 파일들의 구조를 따릅니다:
- XCTest 프레임워크 사용
- `XCTAssertEqual`, `XCTAssertNotNil` 등 사용
- `@Test` 또는 `func test` 형식
