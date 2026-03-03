# 매크로 시스템

ServiceAttach의 매크로 구현 원리를 안내합니다.

## 매크로 구현 패턴

모든 매크로는 `AccessorMacro` 프로토콜을 따릅니다.

```swift
public struct InstanceMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax]
}
```

## 매크로 확장 단계

1. **인자 파싱** - `node.arguments`에서 파라미터 추출
2. **검증** - `VariableDeclSyntax` 확인 및 유효성 검사
3. **타입 추출** - 프로퍼티 타입 파싱
4. **에러 처리** - `MacroError`로 컴파일 타임 에러 생성
5. **코드 생성** - getter 생성 (`Container.resolveOptional` 호출)

## 생성되는 코드

`@Instance`가 붙은 프로퍼티는 다음과 같은 getter가 생성됩니다:

```swift
var service: Service! {
    get {
        guard let instance: Service = Container.resolve(Service.self) else {
            fatalError("Service 인스턴스를 찾을 수 없습니다")
        }
        return instance
    }
}
```

## MacroError

[`MacroError.swift`](../../Sources/ServiceAttachMacros/MacroError.swift)에 정의된 에러:

- `nameNotFound` - 이름을 찾을 수 없습니다
- `typeNotSupported` - 지원하지 않는 타입입니다
- `expressionRequired` - 매개변수가 필요합니다
- `noInheritance` - 상속 타입이 없습니다
- `noOptionalSupported` - 옵셜을 지원하지 않습니다
- `onlyOptionalSupported` - 옵셜만 지원합니다

## 매크로 추가 방법

1. `Sources/ServiceAttach/`에 공개 매크로 선언 추가
2. `Sources/ServiceAttachMacros/Macros/`에 구현체 추가
3. `ServiceAttachMacro.swift`의 `providingMacros` 배열에 등록
4. `MacroError.swift`에 필요한 에러 케이스 추가
5. 테스트 파일 추가
