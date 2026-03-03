//
//  SharedMacro.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//  Refactored to use BaseScopeMacro
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SharedMacro: BaseScopeMacro {
    public var scopeType: MacroScope = .shared

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let macro = SharedMacro()

        // impl 인자 파싱
        let implArg = node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .map(\.expression.trimmedDescription)
            .first

        // VariableDeclSyntax 검증
        guard let varSyntax = declaration.as(VariableDeclSyntax.self) else {
            MacroError
                .typeNotSupported
                .createDiagnostic(declaration, context)
            return []
        }

        MacroError.onlyOneBindedPropertySupported
            .create(declaration, context, when: varSyntax.bindings.count != 1)

        guard let rawType = varSyntax.bindings.first?.typeAnnotation?.type.trimmedDescription else { return [] }
        let type = Helper.removeSpecialCharacters(rawType)

        // 옵셔널 타입 체크
        macro.validateOptionalSupport(rawType, declaration: declaration, context: context, supported: false)

        // resolve 코드 생성
        let resolveCode = macro.generateResolveCode(
            type: type,
            rawType: rawType,
            implArg: implArg,
            scope: macro.scopeType
        )

        return [
            resolveCode
        ]
    }
}
