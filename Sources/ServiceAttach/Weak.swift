//
//  Week.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

/// weak 참조로 인스턴스를 주입합니다.
///
/// `@Weak`는 **weak scope**를 사용하여,
/// 참조하는 객체가 해제되면 자동으로 인스턴스도 해제됩니다.
///
/// ```swift
/// @Weak(varName: "output")
/// var interactor: Interactor!
/// ```
///
/// - Important: 반드시 암시적으로 언래핑된 옵셔널 타입(`Type!`)이어야 합니다.
/// - Parameter varName: 연결할 프로퍼티 이름
///
/// - Tag: weakMacro
@attached(accessor, names: arbitrary)
public macro Weak(varName: String) = #externalMacro(module: "ServiceAttachMacros", type: "WeakMacro")

/// weak 참조로 인스턴스를 주입합니다. (프로토콜 지정)
///
/// `@Weak`는 **weak scope**를 사용하여,
/// 참조하는 객체가 해제되면 자동으로 인스턴스도 해제됩니다.
///
/// ```swift
/// @Weak(varName: "output", protocols: MyProtocol.self)
/// var interactor: Interactor!
/// ```
///
/// - Important: 반드시 암시적으로 언래핑된 옵셔널 타입(`Type!`)이어야 합니다.
/// - Parameter varName: 연결할 프로퍼티 이름
/// - Parameter protocols: 준수해야 할 프로토콜 타입
///
/// - Tag: weakMacroWithProtocol
@attached(accessor, names: arbitrary)
public macro Weak(varName: String, protocols: AnyObject.Type) = #externalMacro(module: "ServiceAttachMacros", type: "WeakMacro")
