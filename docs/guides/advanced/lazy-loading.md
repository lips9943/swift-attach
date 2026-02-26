# 지연 초기화 (Lazy Loading)

`@Lazy` 매크로를 사용하여 인스턴스의 생성을 지연시키는 방법을 안내합니다.

## 기본 개념

`@Lazy`는 첫 접근 시 인스턴스를 생성하고, **weak scope**로 자동 등록합니다.

### 일반적인 사용

```swift
@Lazy
var heavyService: HeavyService

// 첫 접근 시 생성됨
heavyService.doSomething()

// 이후 접근은 같은 인스턴스
heavyService.doSomethingElse()
```

## 동작 방식

1. 첫 접근 시 `Container`에 인스턴스 생성 및 등록 (weak scope)
2. 이후 접근은 등록된 인스턴스 반환
3. 참조가 모두 사라지면 자동 해제

## 프로토콜에 구현체 지정

```swift
@Lazy(impl: MyServiceImpl.self)
var lazyProtocol: MyProtocol
```

## 사용 사례

- 초기화 비용이 큰 객체
- 사용되지 않을 수 있는 기능
- 메모리를 효율적으로 관리해야 하는 경우
