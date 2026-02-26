# ServiceAttach 문서화 시스템 디자인

**날짜:** 2026-02-26
**상태:** 승인됨
**접근 방식:** C형 하이브리드 (DocC + 수동 가이드)

## 개요

ServiceAttach 프로젝트의 문서화 시스템 설계. README.md, docs/ 폴더 문서, 코드 주석 세 가지를 단일 진실 공급원(Single Source of Truth) 원칙으로 통합하여 중복을 최소화하고 일관성을 유지한다.

## 타겟 독자

- **사용자**: ServiceAttach를 사용하는 앱 개발자
- **기여자**: 프로젝트에 기여하는 개발자
- 양쪽 모두를 위한 포괄적인 문서화 제공

## 전체 구조

```
swift-attach/
├── README.md                    # 입문용 개요 + 빠른 시작
├── CLAUDE.md                    # Claude Code 가이드 (기존 유지)
├── Package.swift
├── docs/
│   ├── getting-started.md       # 사용 시작 가이드
│   ├── guides/                  # 개념별 상세 가이드
│   │   ├── scopes.md            # Scope 시스템 설명
│   │   ├── macros.md            # 매크로 사용법
│   │   ├── container.md         # Container 사용법
│   │   └── advanced/            # 심화 주제
│   │       ├── lazy-loading.md
│   │       └── error-handling.md
│   ├── architecture/            # 아키텍처 문서
│   │   ├── overview.md          # 전체 아키텍처
│   │   ├── macro-system.md      # 매크로 구현 원리
│   │   └── contributing.md      # 기여 가이드
│   └── api/                     # DocC 출력 (자동 생성)
│       └── .docc-build/         # DocC 빌드 결과
├── scripts/
│   └── docs/
│       └── generate.sh          # DocC 문서 생성 스크립트
├── Makefile                     # 문서 빌드 명령어
└── Sources/
    └── ServiceAttach/
        └── (DocC 주석 포함 코드)
```

## 문서 간 참조 관계

```
README.md
    ├── "더 자세한 내용은 docs/getting-started.md 참조"
    └── "API 레퍼런스는 docs/api/ 확인"

docs/getting-started.md
    ├── "Scope 상세는 docs/guides/scopes.md"
    ├── "API 문서는 코드 주석 또는 docs/api/"
    └── "내부 동작은 docs/architecture/overview.md"

코드 주석 (///)
    └── DocC 형식으로 작성 → `swift docc`로 docs/api/로 변환
```

## 각 문서의 역할

### 1. README.md

**목적:** 5분 안에 프로젝트 이해 및 시작

**내용:**
- 프로젝트 개요 (한 문장)
- 핵심 기능 목록
- 빠른 시작 (복사-붙여넣기 가능한 코드)
- 문서 인덱스
- 라이선스

**하지 않는 것:**
- 상세 설명 (docs/로 위임)
- API 레퍼런스 (DocC로 위임)

### 2. docs/getting-started.md

**목적:** 처음 사용자를 위한 단계별 가이드

**내용:**
- 설치 방법
- 첫 번째 예제
- 기본 개념 소개
- 다음 단계 링크

### 3. docs/guides/

**목적:** 개념별 상세 가이드

**파일:**
- `scopes.md` - Scope 시스템 (transient, shared, weak)
- `macros.md` - 모든 매크로 사용법
- `container.md` - Container 직접 사용법
- `advanced/` - 심화 주제

**원칙:**
- 코드 주석의 내용을 참조, 중복 작성 금지
- 코드가 있는 위치 링크 제공
- 학습 순서 고려

### 4. docs/architecture/

**목적:** 내부 구현 이해 및 기여자 가이드

**파일:**
- `overview.md` - 전체 아키텍처
- `macro-system.md` - 매크로 구현 원리
- `contributing.md` - 기여 가이드

### 5. 코드 주석 (DocC)

**목적:** API 레퍼런스의 단일 진실 공급원

**형식:**
```swift
/// Service의 인스턴스를 매번 새로 생성하여 주입합니다.
///
/// `@Instance`는 **transient scope**를 사용하여,
/// 접근할 때마다 새로운 인스턴스가 생성됩니다.
///
/// ```swift
/// @Instance
/// var service: MyService!
/// ```
///
/// - Important: 옵셜 타입(`Type?`)은 지원하지 않습니다.
/// - Tag: instanceMacro
@attached(accessor, names: named(getter))
public macro Instance(impl: Any.Type? = nil)
```

**DocC 필드:**
| 필드 | 용도 | 필수 여부 |
|------|------|----------|
| 요약 (첫 줄) | 간단한 설명 | 필수 |
| 상세 설명 | 동작 원리, 예시 | 선택 |
| Important | 중요 제약사항 | 선택 |
| Note | 참고 정보 | 선택 |
| Parameter | 파라미터 설명 | 파라미터 있으면 필수 |
| Tag | 문서 그룹핑 | 권장 |
| Example | 코드 예시 | 권장 |

## 자동화

### DocC 빌드 스크립트

`scripts/docs/generate.sh`:
```bash
#!/bin/bash
set -e
OUTPUT_DIR="docs/api"
SOURCE_MODULE="ServiceAttach"

swift package generate-documentation \
  --target $SOURCE_MODULE \
  --output-path $OUTPUT_DIR \
  --transform-for-static-hosting \
  --hosting-base-path /api \
  --index
```

### Makefile

```makefile
.PHONY: docs help

help:
	@echo "make docs    - DocC 문서 생성"

docs:
	./scripts/docs/generate.sh
```

### 개발 워크플로우

```
1. 코드 변경
       ↓
2. DocC 주석 업데이트 (///)
       ↓
3. make docs
       ↓
4. docs/api/ 자동 생성
       ↓
5. git add/commit/push
```

## 스타일 가이드라인

### 문서 작성 원칙

1. **단일 진실 공급원**
   - API 설명은 코드 주석이 원본
   - docs/는 주석 참조, 중복 금지
   - README는 docs/ 요약

2. **한국어 우선**
   - 주요 설명은 한국어
   - 코드 식별자, 기술 용어는 영어 유지
   - DocC 주석도 한국어

3. **학습 순서**
   - 입문 → 기본 → 심화 → 참조
   - 선행 지식 없이도 순차 학습 가능

### 마크다운 스타일

```markdown
# H1: 파일당 하나

## H2: 주요 구분
### H3: 상세 구분
#### H4: 지양

- **굵게**: 중요 개념, 매크로 이름
- `코드`: 식별자, 파일명

> **Note:** 참고
> **Important:** 경고
```

### 파일명 규칙

| 위치 | 규칙 | 예시 |
|------|------|------|
| 루트 | README.md | README.md |
| docs/ | 소문자, 하이픈 | getting-started.md |
| docs/guides/ | 주제별 | scopes.md |
| docs/architecture/ | 주제별 | overview.md |
| 디자인 문서 | YYYY-MM-DD-제목-design.md | 2026-02-26-lazy-macro-design.md |

## 참조 링크 규칙

| 참조 대상 | 문법 | 예시 |
|----------|------|------|
| 다른 docs 문서 | 상대 경로 | `[Scope 가이드](guides/scopes.md)` |
| 코드 파일 | 상대 경로 + 행 | [`Container.swift:15`](../Sources/.../Container.swift:15) |
| DocC 문서 | DocC 링크 | `` ``Container`` `` |
| 외부 링크 | 절대 URL | `[Swift Macros](https://...)` |

## 구현 우선순위

1. **Phase 1**: README.md 작성
2. **Phase 2**: DocC 주석 추가 (핵심 파일)
3. **Phase 3**: docs/getting-started.md 작성
4. **Phase 4**: docs/guides/ 작성
5. **Phase 5**: docs/architecture/ 작성
6. **Phase 6**: 자동화 스크립트 추가
7. **Phase 7**: CI 통합 (선택)

## 성공 기준

- [ ] 사용자가 README만 보고 5분 안에 첫 예제 실행 가능
- [ ] API 설명 중복이 없음 (코드 주석이 유일한 출처)
- [ ] 모든 공개 API에 DocC 주석이 있음
- [ ] `make docs`로 문서 자동 생성 가능
- [ ] 입문자가 순서대로 읽으며 학습 가능

## 관련 문서

- [Swift-DocC Documentation](https://www.swift.org/documentation/docc/)
- [Swift Package Manager Documentation](https://www.swift.org/documentation/package-manager/)
