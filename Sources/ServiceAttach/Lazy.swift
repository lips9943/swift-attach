//
//  Lazy.swift
//  ServiceAttach
//
//  Created by Claude on 2/26/26.
//

/// 지연 초기화 인스턴스를 주입합니다.
///
/// `@Lazy`는 첫 접근 시 인스턴스를 생성하고,
/// **weak scope**로 자동 등록합니다.
///
/// ```swift
/// @Lazy
/// var heavyService: HeavyService
///
/// // 첫 접근 시 생성
/// heavyService.doSomething()
/// ```
///
/// - Note: 프로토콜 타입에 주입 시 `impl` 파라미터로 구현체를 지정하세요.
///
/// ### Example
/// ```swift
/// @Lazy(impl: MyServiceImpl.self)
/// var lazyProtocol: MyProtocol
/// ```
///
/// - Tag: lazyMacro
@attached(accessor, names: named(getter))
public macro Lazy(impl: Any.Type? = nil) = #externalMacro(
    module: "ServiceAttachMacros",
    type: "LazyMacro"
)
