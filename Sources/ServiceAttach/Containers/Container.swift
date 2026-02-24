//
//  Container.swift
//  Injective
//
//  Created by Jun on 12/25/25.
//
import Combine
import Foundation


public final class Container: ContainerType {
    private let lock = NSLock()
    private lazy var storage: [String: () -> Any] = [:]
    private lazy var singletonStorage: [String: Any] = [:]
    private lazy var weakStorage: [String: Any] = [:]
    
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
            if let transient = weakStorage[key] as? T { return transient }
            let result = transient() as? T
            weakStorage[key] = result
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
            weakStorage[key] = value()
        }
    }
}
