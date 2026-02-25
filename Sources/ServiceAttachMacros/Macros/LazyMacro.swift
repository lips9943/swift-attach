//
//  LazyMacro.swift
//  ServiceAttach
//
//  Created by Claude on 2/26/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators

public struct LazyMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
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

        // 옵셔널 타입 체크
        MacroError
            .noOptionalSupported
            .create(declaration, context, when: rawType.contains("?"))

        // getter 코드 생성은 다음 단계에서
        return []
    }
}
