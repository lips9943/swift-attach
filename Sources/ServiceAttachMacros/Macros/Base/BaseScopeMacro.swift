//
//  BaseScopeMacro.swift
//  ServiceAttach
//
//  Created for macro quality refactoring
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// 스코프 타입 (매크로 내부용)
public enum MacroScope {
    case transient
    case shared
    case weak

    var codeValue: String {
        switch self {
        case .transient: return ".transient"
        case .shared: return ".shared"
        case .weak: return ".weak"
        }
    }
}

/// 모든 스코프 매크로의 기반이 되는 프로토콜
public protocol BaseScopeMacro: AccessorMacro {
    /// 매크로가 사용하는 스코프 타입
    var scopeType: MacroScope { get }

    /// 옵셔널 타입 검증 (선택적 구현)
    /// - Parameters:
    ///   - type: 검증할 타입 문자열
    ///   - declaration: 선언 구문
    ///   - context: 매크로 확장 컨텍스트
    func validateOptionalType(_ type: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext)
}

public extension BaseScopeMacro {
    /// 기본 옵셔널 검증 (아무것도 하지 않음)
    func validateOptionalType(_ type: String, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext) {}

    /// 옵셔널 지원 여부 검증 헬퍼
    func validateOptionalSupport(
        _ rawType: String,
        declaration: some DeclSyntaxProtocol,
        context: some MacroExpansionContext,
        supported: Bool
    ) {
        if supported {
            // 옵셔널만 허용
            MacroError.onlyOptionalSupported.create(declaration, context, when: !rawType.contains("?"))
        } else {
            // 옵셔널 불허
            MacroError.noOptionalSupported.create(declaration, context, when: rawType.contains("?"))
        }
    }

    /// resolve 코드 생성 헬퍼
    func generateResolveCode(
        type: String,
        rawType: String,
        implArg: String?,
        scope: MacroScope
    ) -> AccessorDeclSyntax {
        var resolveType: String = ""
        var impl: String = ""
        var protocolType: String = ""

        // impl 인자가 있는 경우
        if let implArg {
            let typeName = Helper.removeSelf(type: implArg)
            resolveType = implArg + ","
            impl = "\(typeName)()"
            protocolType = "protocol: \(type).self,"
        } else {
            resolveType = type + ".self, "
            impl = "\(type)()"
        }

        let scopeValue = scope.codeValue
        return """
        get {
            let ctn = Container.shared
            if let instance = ctn.resolveOptional(\(raw: resolveType)\(raw: protocolType) scope: \(raw: scopeValue)) {
                return instance
            } else {
                let impl = \(raw: impl)
                ctn.register(\(raw: protocolType)impl: impl, scope: \(raw: scopeValue))
                return impl
            }
        }
        """
    }
}
