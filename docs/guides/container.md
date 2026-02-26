# Container 사용법

매크로 없이 `Container`를 직접 사용하는 방법을 안내합니다.

## 인스턴스 등록

```swift
// shared 스코프로 등록
Container.register(MyService(), scope: .shared)

// weak 스코프로 이름 지정하여 등록
Container.register(interactor, scope: .weak, name: "output")
```

## 인스턴스 resolve

```swift
// 타입으로 resolve
if let service: MyService = Container.resolve(MyService.self) {
    service.doSomething()
}

// 이름으로 resolve
if let interactor: Interactor = Container.resolve(Interactor.self, name: "output") {
    interactor.doSomething()
}
```

## 인스턴스 해제

```swift
// 특정 타입 해제
Container.unregister(MyService.self)

// 이름으로 해제
Container.unregister(Interactor.self, name: "output")

// 여러 타입 한번에 해제
Container.unregisterObjects((MyService.self, nil), (Interactor.self, "output"))
```

> **구현:** [`Container`](../Sources/ServiceAttach/Containers/Container.swift) 소스 코드를 참조하세요.
