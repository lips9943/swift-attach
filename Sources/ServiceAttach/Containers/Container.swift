/// Swift Macros를 사용한 의존성 주입(Dependency Injection) 라이브러리입니다.
///
/// ServiceAttach는 컴파일 타임에 매크로를 확장하여
/// 타입 안전한 의존성 주입을 제공합니다.
///
/// - Important: Swift 6.2+가 필요합니다.
///
/// ## Topics
///
/// ### Macros
/// - ``Instance``
/// - ``Shared``
/// - ``Weak``
/// - ``Lazy``
/// - ``Unregister``
///
/// ### Containers
/// - ``Container``
/// - ``Scope``
///
//  Container.swift
//  Injective
//
//  Created by Jun on 12/25/25.
//
import Combine
import Foundation

// Weak 참조를 위한 래퍼 클래스
private class WeakBox<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

public final class Container: ContainerType {
    private let lock = NSLock()
    private lazy var storage: [String: () -> Any] = [:]
    private lazy var singletonStorage: [String: Any] = [:]
    private lazy var weakStorage: [String: WeakBox<AnyObject>] = [:]

    nonisolated(unsafe) public static let shared = Container()
    
    public init() {}
    
    /// 인스턴스 기본 등록
    public func register<T>(impl value: @autoclosure @escaping () -> T) {
        let key = makeKey(T.self, protocols: nil, scope: .transient)
        _registerByScope(key: key, impl: value, scope: .transient)
    }
    
    public func register<T>(impl value: @autoclosure @escaping () -> T, scope: Scope = .transient) {
        let key = makeKey(T.self, protocols: nil, scope: scope)
        _registerByScope(key: key, impl: value, scope: scope)
    }
    
    public func register<T, P>(protocol: P.Type, impl value: @autoclosure @escaping () -> T,  scope: Scope = .transient) {
        let key = makeKey(T.self, protocols: `protocol`, scope: scope)
        _registerByScope(key: key, impl: value, scope: scope)
    }
    
    // 모듈로 등록
//    func register(by modules: [ContainerModule]) {
//        for module in modules {
//            module.register(in: self)
//        }
//    }
    
//    public func resolve<T>(_ type: T.Type, scope: Scope = .transient) -> T {
//        guard let value: T = resolveOptional(type, scope: scope) else { fatalError("등록되지 않은 타입: \(T.self)") }
//        return value
//    }
//    
//    public func resolve<T, P>(_ type: T.Type, protocol: P.Type, scope: Scope = .transient) -> T {
//        guard let value: T = resolveOptional(type, protocol: `protocol`, scope: scope) else { fatalError("등록되지 않은 타입: \(T.self)") }
//        return value
//    }
    
    public func resolveOptional<T>(_ type: T.Type, scope: Scope = .transient) -> T? {
        lock.lock()
        defer { lock.unlock() }
        let key = makeKey(type, protocols: nil, scope: scope)
        
        // 기본 등록된 인스턴스
        guard let transient = storage[key] else { return nil }
        
        return _resolveWithScope(key: key, transient: transient, scope: scope)
    }
    
    public func resolveOptional<T, P>(_ type: T.Type, protocol: P.Type, scope: Scope = .transient) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = makeKey(type, protocols: `protocol`, scope: scope)
        
        // 기본 등록된 인스턴스
        guard let transient = storage[key] else { return nil }
        
        return _resolveWithScope(key: key, transient: transient, scope: scope)
    }
    
    public func unregister<T>(type: T.Type, protocol: Any.Type?) {
        lock.lock()
        defer { lock.unlock() }
        let key = makeKey(type, protocols: `protocol`, scope: .transient)
        singletonStorage.removeValue(forKey: key)
        weakStorage.removeValue(forKey: weakString + key)
        storage.removeValue(forKey: key)
    }
    
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        singletonStorage.removeAll()
        weakStorage.removeAll()
        storage.removeAll()
    }
}



extension Container {
    private var weakString: String { "weak " }
    
    private func makeKey(_ type: Any.Type, protocols: Any.Type?, scope: Scope) -> String {
        let fixedType = String(reflecting: type).replacingOccurrences(of: ".Type", with: "")
        var key: String = scope == .weak ? weakString + fixedType : fixedType
        if let protocols {
            let fixedProtocol = String(reflecting: protocols).replacingOccurrences(of: ".Type", with: "")
            key.append(" : ")
            key.append(fixedProtocol)
        }
        
        return key
    }
    
    private func _resolveWithScope<T>(key: String, transient: () -> Any, scope: Scope) -> T? {
        switch scope {
        case .transient:
            return transient() as? T
        case .shared:
            if let transient = singletonStorage[key] as? T { return transient }
            let result = transient() as? T
            singletonStorage[key] = result
            return result
        case .weak:
            // weak 박스에서 값 가져오기
            if let weakBox = weakStorage[key], let value = weakBox.value as? T {
                return value
            }
            // 없으면 새로 생성하고 weak 박스에 저장
            guard let result = transient() as? T, let objectResult = result as? AnyObject else {
                return nil
            }
            weakStorage[key] = WeakBox(objectResult)
            return result
        }
    }
    
    private func _registerByScope(key: String, impl value: @escaping () -> Any, scope: Scope) {
        storage[key] = value
        switch scope {
        case .shared:
            singletonStorage[key] = value()
        case .transient:
            break
        case .weak:
            // weak 박스에 래핑하여 저장
            if let objectValue = value() as? AnyObject {
                weakStorage[key] = WeakBox(objectValue)
            }
        }
    }
}
