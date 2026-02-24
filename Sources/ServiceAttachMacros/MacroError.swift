//
//  MacroError.swift
//  Service Attach
//
//  Created by Jun on 12/28/25.
//
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public enum MacroError: LocalizedError {
    case nameNotFound
    case typeNotSupported
    case expressionRequired
    case noInheritance
    case onlyOneBindedPropertySupported
    case noOptionalSupported
    case onlyOptionalSupported
    case typeMustHaveInterrogationMark
    
    public var errorDescription: String? {
        switch self {
        case .nameNotFound:
            "이름을 찾을 수 없습니다."
        case .typeNotSupported:
            "지원하지 않는 타입입니다."
        case .expressionRequired:
            "어노테이션의 매개변수를 입력해주십시오."
        case .noInheritance:
            "매치되는 상속 타입이 없습니다."
        case .onlyOneBindedPropertySupported:
            "한가지 프로퍼티만 주입받을 수 있습니다."
        case .noOptionalSupported:
            "옵셔널 프로퍼티는 지원하지 않습니다."
        case .onlyOptionalSupported:
            "옵셔널 프로퍼티 외 지원하지 않습니다."
        case .typeMustHaveInterrogationMark:
            "물음표 마크가 반드시 포함되어야합니다."
        }
    }
    
    public func create(_ decl: some SyntaxProtocol,
                       _ context: some MacroExpansionContext,
                       when compare: @autoclosure () -> Bool) {
        if compare() {
            guard let errorDescription else { return }
            context.diagnose(
                Diagnostic(node: decl, message: MacroExpansionErrorMessage(errorDescription)))
        }
    }
    
    public func createDiagnostic(_ decl: some SyntaxProtocol, _ context: some MacroExpansionContext) {
        guard let errorDescription else { return }
        context.diagnose(
            Diagnostic(node: decl, message: MacroExpansionErrorMessage(errorDescription))
        )
    }
}
