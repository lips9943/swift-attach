# ServiceAttach 시작하기

ServiceAttach를 사용하여 Swift 프로젝트에 의존성 주입을 적용하는 방법을 안내합니다.

## 설치

### Swift Package Manager

`Package.swift`에 의존성을 추가합니다:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-attach", from: "1.0.0")
]

// 타겟 의존성
.targets(
    name: "MyApp",
    dependencies: ["ServiceAttach"]
)
```

Xcode에서는 **File → Add Package Dependencies...**에서 패키지 URL을 추가하세요.

## 첫 번째 예제

### 1. 기본 서비스 정의

```swift
import ServiceAttach

// 서비스 클래스
class UserService {
    func greet() -> String {
        "Hello, ServiceAttach!"
    }
}
```

### 2. @Shared로 싱글톤 주입

```swift
@Shared
var userService: UserService!

func greetUser() {
    print(userService.greet()) // "Hello, ServiceAttach!"
}
```

### 3. @Instance로 매번 새 인스턴스

```swift
@Instance
var logger: Logger!

func logSomething() {
    logger.log("Something happened") // 매번 새 Logger 인스턴스
}
```

## 다음 단계

- [Scope 가이드](guides/scopes.md) - 스코프 시스템 이해하기
- [매크로 가이드](guides/macros.md) - 모든 매크로 상세 사용법
- [API 레퍼런스](api/) - 전체 API 문서
