//
//  Unregister.swift
//  ServiceAttach
//
//  Created by 고혁준 on 1/5/26.
//

/// 객체 해제 시 자동으로 등록된 인스턴스를 제거합니다.
///
/// `@Unregister`는 `deinit`에서 자동으로 `unregisterObjects()`를 호출하여
/// weak 참조로 연결된 인스턴스를 정리합니다.
///
/// ```swift
/// @Unregister(type: (Presenter.self, nil), (Router.self, nil))
/// class MyView {
///     // deinit에서 자동으로 unregisterObjects() 호출
/// }
/// ```
///
/// - Parameter type: 해제할 타입과 이름의 튜플 목록
///
/// - Tag: unregisterMacro
@attached(extension, names: arbitrary)
public macro Unregister(type: (Any.Type, Any.Type?)...) = #externalMacro(module: "ServiceAttachMacros", type: "UnregisterMacro")
