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

/// Weak 참조를 위한 래퍼 클래스
private class WeakBox<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

/// 컨테이너의 내부 상태를 관리하는 스레드-safe 저장소
private final class ContainerStorage: @unchecked Sendable {
    private init() {}
    private let lock = NSLock()
    
    static let shared: ContainerStorage = .init()
    var storage: [String: () -> Any] = [:]
    var singletonStorage: [String: Any] = [:]
    var weakStorage: [String: WeakBox<AnyObject>] = [:]

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// 의존성 주입을 위한 컨테이너입니다.
///
/// `AttachContainer`는 객체의 생명주기를 관리하고 인스턴스를 등록/해제합니다.
/// Swift 6 Concurrency 모델을 준수하기 위해 내부 상태는 별도의 스레드-safe 저장소로 관리합니다.
public struct Container {
    private let container = ContainerStorage.shared
    public init() {}
    /// 인스턴스 기본 등록
    ///
    /// - Parameter value: 등록할 인스턴스
    func register<T>(impl value: @autoclosure @escaping () -> T) {
        let key = makeKey(T.self, protocols: nil, scope: .transient)
        guard !hasKey(key: key) else { return }
        _registerByScope(key: key, impl: value, scope: .transient)
    }

    /// 지정된 스코프로 인스턴스를 등록합니다.
    ///
    /// - Parameters:
    ///   - value: 등록할 인스턴스
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    public nonisolated func register<T>(impl value: @autoclosure @escaping () -> T, scope: Scope = .transient) {
        let key = makeKey(T.self, protocols: nil, scope: scope)
        guard !hasKey(key: key) else { return }
        _registerByScope(key: key, impl: value, scope: scope)
    }

    /// 프로토콜 타입으로 인스턴스를 등록합니다.
    ///
    /// - Parameters:
    ///   - protocol: 프로토콜 타입
    ///   - value: 등록할 인스턴스
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    public nonisolated func register<T, P>(protocol: P.Type, impl value: @autoclosure @escaping () -> T,  scope: Scope = .transient) {
        let key = makeKey(T.self, protocols: `protocol`, scope: scope)
        guard !hasKey(key: key) else { return }
        _registerByScope(key: key, impl: value, scope: scope)
    }
    
    /// 지정된 타입과 스코프로 인스턴스를 resolve합니다. (throwing 버전)
    ///
    /// - Parameters:
    ///   - type: resolve할 타입
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    /// - Returns: resolve된 인스턴스
    /// - Throws: ContainerError 타입이 등록되지 않은 경우
    public nonisolated func resolve<T>(_ type: T.Type, scope: Scope = .transient) throws -> T {
        let key = makeKey(type, protocols: nil, scope: scope)

        guard let transient = container.withLock({ container.storage[key] }) else {
            throw ContainerError.typeNotRegistered(type: String(describing: type), scope: String(describing: scope))
        }

        guard let result: T = _resolveWithScope(key: key, transient: transient, scope: scope) else {
            throw ContainerError.typeNotRegistered(type: String(describing: type), scope: String(describing: scope))
        }

        return result
    }

    /// 프로토콜 타입으로 인스턴스를 resolve합니다. (throwing 버전)
    ///
    /// - Parameters:
    ///   - type: resolve할 타입
    ///   - protocol: 프로토콜 타입
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    /// - Returns: resolve된 인스턴스
    /// - Throws: ContainerError 타입이 등록되지 않은 경우
    public nonisolated func resolve<T, P>(_ type: T.Type, protocol: P.Type, scope: Scope = .transient) throws -> T {
        let key = makeKey(type, protocols: `protocol`, scope: scope)

        guard let transient = container.withLock({ container.storage[key] }) else {
            throw ContainerError.typeNotRegistered(type: String(describing: type), scope: String(describing: scope))
        }

        guard let result: T = _resolveWithScope(key: key, transient: transient, scope: scope) else {
            throw ContainerError.typeNotRegistered(type: String(describing: type), scope: String(describing: scope))
        }

        return result
    }

    /// 지정된 타입과 스코프로 인스턴스를 resolve합니다.
    ///
    /// - Parameters:
    ///   - type: resolve할 타입
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    /// - Returns: resolve된 인스턴스 또는 nil
    /// - Note: 내부적으로 throwing resolve()를 사용하며 에러를 무시합니다.
    public nonisolated func resolveOptional<T>(_ type: T.Type, scope: Scope = .transient) -> T? {
        try? resolve(type, scope: scope)
    }

    /// 프로토콜 타입으로 인스턴스를 resolve합니다.
    ///
    /// - Parameters:
    ///   - type: resolve할 타입
    ///   - protocol: 프로토콜 타입
    ///   - scope: 인스턴스의 생명주기 (기본값: `.transient`)
    /// - Returns: resolve된 인스턴스 또는 nil
    /// - Note: 내부적으로 throwing resolve()를 사용하며 에러를 무시합니다.
    public nonisolated func resolveOptional<T, P>(_ type: T.Type, protocol: P.Type, scope: Scope = .transient) -> T? {
        try? resolve(type, protocol: `protocol`, scope: scope)
    }
    
    /// 프로토콜 타입의 인스턴스를 register와 동시에 resolve합니다.
    public nonisolated func autoResolve<T, P>(impl value: @autoclosure @escaping () -> T, protocol: P.Type, scope: Scope = .transient) -> T {
        let key = makeKey(T.self, protocols: `protocol`, scope: scope)
        if !hasKey(key: key) {
            _registerByScope(key: key, impl: value, scope: scope)
        }
        
        guard let transient = container.withLock({ container.storage[key] }) else {
            return value()
        }

        guard let result: T = _resolveWithScope(key: key, transient: transient, scope: scope) else {
            return value()
        }
        
        return result
    }
    
    

    /// 등록된 인스턴스를 해제합니다.
    ///
    /// - Parameters:
    ///   - type: 해제할 타입
    ///   - protocol: 프로토콜 타입 (nil인 경우 구체 타입)
    public nonisolated func unregister<T>(type: T.Type, protocol: Any.Type?) {
        let key = makeKey(type, protocols: `protocol`, scope: .transient)
        container.withLock {
            container.singletonStorage.removeValue(forKey: key)
            container.weakStorage.removeValue(forKey: weakString + key)
            container.storage.removeValue(forKey: key)
        }
    }

    /// 모든 등록된 인스턴스를 해제합니다.
    public nonisolated func clearAll() {
        container.withLock {
            container.singletonStorage.removeAll()
            container.weakStorage.removeAll()
            container.storage.removeAll()
        }
    }
}

extension Container {
    ///
    public func resolve<P>(impl value: String, protocol: P.Type, scope: Scope = .transient) -> P? {
        let key = makeKey(value, protocols: `protocol`, scope: scope)

        guard let transient = container.withLock({ container.storage[key] }) else { return nil }
        
        let result: P? = _resolveWithScope(key: key, transient: transient, scope: scope)

        return result
    }
}

extension Container {
    private nonisolated var weakString: String { "weak " }
    
    private nonisolated func hasKey(key: String) -> Bool {
        return container.storage.contains { $0.key == key }
    }

    private nonisolated func makeKey(_ type: Any.Type, protocols: Any.Type?, scope: Scope) -> String {
        let fixedType = String(reflecting: type).replacingOccurrences(of: ".Type", with: "")
        var key: String = scope == .weak ? weakString + fixedType : fixedType
        if let protocols {
            let fixedProtocol = String(reflecting: protocols).replacingOccurrences(of: ".Type", with: "")
            key.append(" : ")
            key.append(fixedProtocol)
        }

        return key
    }
    
    private nonisolated func makeKey(_ type: String, protocols: Any.Type?, scope: Scope) -> String {
        var key: String = scope == .weak ? weakString + type : type
        if let protocols {
            let fixedProtocol = String(reflecting: protocols).replacingOccurrences(of: ".Type", with: "")
            key.append(" : ")
            key.append(fixedProtocol)
        }

        return key
    }

    private nonisolated func _resolveWithScope<T>(key: String, transient: () -> Any, scope: Scope) -> T? {
        switch scope {
        case .transient:
            return transient() as? T
        case .shared:
            return container.withLock {
                if let cached = container.singletonStorage[key] as? T { return cached }
                let result = transient() as? T
                container.singletonStorage[key] = result
                return result
            }
        case .weak:
            return container.withLock {
                // weak 박스에서 값 가져오기
                if let weakBox = container.weakStorage[key], let value = weakBox.value as? T {
                    return value
                }
                // 없으면 새로 생성하고 weak 박스에 저장
                guard let result = transient() as? T else {
                    return nil
                }
                // AnyObject로 변환 (class 타입만 weak 지원)
                let objectResult = result as AnyObject
                container.weakStorage[key] = WeakBox(objectResult)
                return result
            }
        }
    }

    private nonisolated func _registerByScope(key: String, impl value: @escaping () -> Any, scope: Scope) {
        container.withLock {
            container.storage[key] = value
            switch scope {
            case .shared:
                container.singletonStorage[key] = value()
            case .transient:
                break
            case .weak:
                // weak 박스에 래핑하여 저장
                let objectValue = value()
                let objectValueAsAnyObject = objectValue as AnyObject
                container.weakStorage[key] = WeakBox(objectValueAsAnyObject)
            }
        }
    }
}
