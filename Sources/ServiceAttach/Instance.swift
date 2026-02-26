/// Service의 인스턴스를 매번 새로 생성하여 주입합니다.
///
/// `@Instance`는 **transient scope**를 사용하여,
/// 접근할 때마다 새로운 인스턴스가 생성됩니다.
///
/// ```swift
/// @Instance
/// var service: MyService!
///
/// func useService() {
///     service.doSomething() // 매번 새 인스턴스
/// }
/// ```
///
/// - Important: 옵셜 타입(`Type?`)은 지원하지 않습니다.
/// - Note: 프로토콜 타입에 주입 시 `impl` 파라미터로 구현체를 지정하세요.
///
/// ### Example
/// ```swift
/// // 구현체 지정 (프로토콜)
/// @Instance(impl: MyServiceImpl.self)
/// var service: MyProtocol!
/// ```
///
/// - Tag: instanceMacro
@attached(accessor, names: named(getter))
public macro Instance(impl: Any.Type? = nil) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "InstanceMacro"
)
