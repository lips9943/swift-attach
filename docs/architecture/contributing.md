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
