# SwiftAttach 🚀

`SwiftAttach`는 **Swift Macros**를 활용하여 컴파일 타임에 타입 안전하고 선언적인 **의존성 주입(Dependency Injection)**을 제공하는 경량 DI 프레임워크입니다.

어노테이션 기반의 간결한 구문으로 의존 관계를 정의하고, 컴파일 타임에 코드 생성을 통해 보일러플레이트 코드 없이 안전하고 유연한 DI 시스템을 구축할 수 있습니다.

---

## 🌟 주요 특징

- **컴파일 타임 안전성**: Swift Macros를 통해 컴파일러가 의존성 주입 코드를 직접 생성하고 검증하므로, 런타임 크래시 위험을 최소화합니다.
- **선언적 어노테이션**: `@Service`, `@AttachConfig`, `@PropertyInjection` 등 명확한 어노테이션으로 가독성을 높입니다.
- **다양한 객체 생명주기(Scope) 지원**:
  - `transient`: 호출할 때마다 매번 새로운 인스턴스를 생성하여 반환합니다.
  - `shared`: 앱 전체에서 인스턴스를 단 하나만 유지하는 싱글톤 패턴을 적용합니다.
  - `weak`: 참조가 존재하는 동안 유지되며, ARC에 의해 해제될 수 있는 weak 레퍼런스 주입입니다.
- **안전한 멀티스레딩**: DI 컨테이너 내부는 `NSLock`을 활용하여 Thread-safe하게 동작하도록 설계되어 있습니다.
- **느슨한 결합**: 프로토콜과 구현체(`Impl` 접미사 표준)의 매핑을 자동화하여 유연한 아키텍처 설계를 돕습니다.

---

## 📂 프로젝트 구조

```text
swift-attach/
├── Package.swift               # 패키지 매니저 정의 (swift-syntax 의존성 포함)
├── Sources/
│   ├── SwiftAttach/            # Core DI Framework 라이브러리
│   │   ├── Containers/
│   │   │   ├── Container.swift       # DI 컨테이너 및 저장소 구현 (Thread-safe)
│   │   │   ├── Scope.swift           # 생명주기(transient, shared, weak) 정의
│   │   │   ├── ContainerError.swift  # 에러 처리를 위한 Enum
│   │   │   └── NonFuncMacros/        # 마커 매크로 선언 (Ignore, NonImplement, Singleton)
│   │   ├── Service.swift             # @Service 매크로 선언
│   │   ├── PropertyInjection.swift   # @PropertyInjection 매크로 선언
│   │   └── AttachConfig.swift        # @AttachConfig 매크로 선언
│   │
│   ├── SwiftAttachMacros/      # Swift Compiler Plugin (매크로 확장 구현체)
│   │   ├── Macros/
│   │   │   ├── ServiceMacro.swift         # @Service 확장 로직 (Member, MemberAttribute)
│   │   │   ├── PropertyInjectionMacro.swift # @PropertyInjection 확장 로직 (Accessor)
│   │   │   ├── AttachConfigMacro.swift    # @AttachConfig 확장 로직 (Member)
│   │   │   └── NonFunc/                   # 마커 매크로의 빈 Peer 확장체들
│   │   ├── Models/                        # AST 파싱용 구문 데이터 모델
│   │   └── Utils/
│   │       └── SyntaxUtil.swift           # SwiftSyntax 파싱 및 분석 유틸리티
│   │
│   └── SwiftAttachClient/      # 테스트 및 예제 애플리케이션
│       ├── main.swift                 # 프레임워크 동작 예시
│       └── ErrorTests.swift           # 에러 핸들링 관련 테스트 시나리오
```

---

## 🛠 매크로 상세 설명

### 1. `@AttachConfig`
- **역할**: DI 컨테이너에 객체를 최초 등록하는 역할을 수행하는 구성(Configuration) 클래스/구조체에 선언합니다.
- **동작 방식**: 내부에 정의된 의존성 생성용 메서드(반환형이 명시된 함수)들을 분석하여, 자동으로 컨테이너에 등록해주는 `init()` 생성자를 빌드 타임에 추가합니다.
```swift
// 사용 예시
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        return RepositoryImpl()
    }
}

// 매크로가 생성하는 코드
// @discardableResult
// init() {
//     let container = SwiftAttach.Container()
//     container.register(protocol: Repository.self, impl: self.getRepository(), scope: .transient)
// }
```

### 2. `@Service`
- **역할**: 의존성 주입이 필요한 클래스/구조체에 선언합니다.
- **동작 방식**:
  1. 클래스 내부에 정의된 인스턴스 변수들을 분석하여 의존성 객체들을 가져오는 비공개(private) 프로퍼티를 자동 생성합니다.
  2. 변수들에 자동으로 `@PropertyInjection` 매크로를 부여합니다.
```swift
// 사용 예시
@Service
class ServiceImpl: Service {
    var repo: Repository!
}

// 매크로가 생성하는 코드
// private let _repo: Repository? = Container().resolve(impl: "RepositoryImpl", protocol: Repository.self, scope: .transient)
//
// @PropertyInjection
// var repo: Repository! {
//     get { _repo }
// }
```

### 3. `@PropertyInjection`
- **역할**: 변수 선언에 부착되어 실제 getter를 비공개 매크로 확장 프로퍼티와 연결해 줍니다. 
- **제약**: 주입 타깃 변수는 반드시 옵셔널(`?`) 혹은 암시적 언래핑 옵셔널(`!`) 타입이어야 합니다.

### 4. 마커 매크로 (Non-Functional Macros)
- `@Singleton`: `@Service` 클래스 내 변수에 선언하여 해당 의존성을 싱글톤(`.shared` 스코프)으로 주입받도록 합니다.
- `@NonImplement`: 표준적인 `[Type]Impl` 이름 규칙이 없는 타입(예: 클래스 인스턴스 직접 사용 등)을 직접 컨테이너에서 검색 및 주입할 때 선언합니다.
- `@Ignore`: 특정 변수를 DI 주입 대상에서 명시적으로 배제합니다.

---

## 💻 사용 예제 (Usage)

`Sources/SwiftAttachClient/main.swift`에 구현된 기본 사용 흐름입니다.

### 1. 프로토콜 및 클래스 정의

```swift
import SwiftAttach

// 프로토콜 정의
protocol Repository {
    var text: String! { get }
}

class RepositoryImpl: Repository {
    var text: String! = "Hello, SwiftAttach!"
}

protocol Service {
    var repo: Repository! { get }
}

// @Service를 사용해 자동으로 의존성을 끌어오도록 설정
@Service
class ServiceImpl: Service {
    var repo: Repository! // RepositoryImpl이 자동으로 주입됨
}
```

### 2. 설정 클래스 작성 (`@AttachConfig`)

```swift
@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        return RepositoryImpl()
    }
    
    func getService() -> Service {
        return ServiceImpl()
    }
}
```

### 3. 애플리케이션 초기화 및 활성화

```swift
struct AppStart {
    init() {
        // configuration 인스턴스를 생성하면 컨테이너에 객체들이 자동 등록됩니다.
        DIConfig() 
    }
}
```

---

## ⚙️ 요구 환경

- **Swift** 6.2 이상 (Swift Syntax 602.0.0-latest 호환)
- **Platforms**: macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+
