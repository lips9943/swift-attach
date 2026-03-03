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

### Swift 6 Concurrency 준수

- **스레드 안전**: `NSLock` 기반 동기화로 데이터 레이스 방지
- **Actor 격리**: 내부 상태는 actor로 보호
- **Nonisolated API**: 모든 공개 메서드는 `await` 없이 호출 가능
- **Sendable 지원**: 모든 공개 타입은 `Sendable` 준수

### 구조화된 에러 처리

```swift
do {
    let service: MyService = try Container.shared.resolve(MyService.self)
} catch ContainerError.typeNotRegistered(let type, let scope) {
    print("\(type) 타입이 \(scope) 스코프에 등록되지 않음")
}
```

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
