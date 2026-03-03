# 에러 처리

ServiceAttach의 컴파일 타임 에러와 해결 방법을 안내합니다.

## 컴파일 타임 에러

### nameNotFound

이름을 찾을 수 없습니다.

```swift
// 에러: name을 지정해야 합니다
@Weak()
var service: Service!

// 수정
@Weak(varName: "output")
var service: Service!
```

### noOptionalSupported

옵셜 타입은 지원하지 않습니다.

```swift
// 에러: 옵셜 타입 사용
@Instance
var service: Service?

// 수정
@Instance
var service: Service!
```

### onlyOptionalSupported

옵셜 타입만 지원합니다.

```swift
// 에러: 옵셜이 아님
@Weak(varName: "output")
var service: Service

// 수정
@Weak(varName: "output")
var service: Service!
```

> **구현:** [`MacroError`](../../Sources/ServiceAttachMacros/MacroError.swift)에서 모든 에러 케이스를 확인하세요.
