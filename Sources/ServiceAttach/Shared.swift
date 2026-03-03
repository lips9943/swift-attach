//
//  Shared.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

/// 싱글톤 인스턴스를 주입합니다.
///
/// `@Shared`는 **shared scope**를 사용하여,
/// 앱 전체에서 공유되는 단일 인스턴스를 제공합니다.
///
/// ```swift
/// @Shared
/// var repository: Repository!
///
/// // 항상 같은 인스턴스
/// repository === repository // true
/// ```
///
/// - Important: 옵셔널 타입(`Type?`)은 지원하지 않습니다.
/// - Note: 상태를 유지해야 하는 객체에 적합합니다.
///
/// ## 구현체 지정
///
/// 프로토콜 타입의 프로퍼티에 구현체를 지정할 수 있습니다:
///
/// ```swift
/// @Shared(impl: RepositoryImpl.self)
/// var repository: RepositoryProtocol!
/// ```
///
/// - Tag: sharedMacro
@attached(accessor, names: arbitrary)
public macro Shared() = #externalMacro(module: "ServiceAttachMacros", type: "SharedMacro")

/// 싱글톤 인스턴스를 주입합니다 (구현체 지정).
///
/// 프로토콜 타입의 프로퍼티에 구현체를 지정하여 사용합니다.
///
/// ```swift
/// @Shared(impl: RepositoryImpl.self)
/// var repository: RepositoryProtocol!
/// ```
///
/// - Important: 옵셔널 타입(`Type?`)은 지원하지 않습니다.
/// - Parameter impl: 구현체 타입
///
/// - Tag: sharedMacroWithImpl
@attached(accessor, names: arbitrary)
public macro Shared(impl: AnyObject.Type) = #externalMacro(module: "ServiceAttachMacros", type: "SharedMacro")
