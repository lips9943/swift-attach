//
//  SharedMacro.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SharedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let implArg = node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .map(\.expression.trimmedDescription)
            .first
        
        guard let varSyntax = declaration.as(VariableDeclSyntax.self) else {
            MacroError
                .typeNotSupported
                .createDiagnostic(declaration, context);
            return []
        }
        
        MacroError.onlyOneBindedPropertySupported
            .create(declaration, context, when: varSyntax.bindings.count != 1)
        
        guard let rawType = varSyntax.bindings.first?.typeAnnotation?.type.trimmedDescription else { return [] }
        let type = Helper.removeSpecialCharacters(rawType)
        var resolveType: String = ""
        var impl: String = ""
        var protocolType: String = ""
        
        // when implementation argument exsists
        if let implArg {
            let typeName = Helper.removeSelf(type: implArg)
            resolveType = implArg + ","
            impl = "\(typeName)()"
            protocolType = "protocol: \(type).self,"
        } else {
            resolveType = type + ".self, "
            impl = "\(type)()"
        }
        
        // optional Type Check
        MacroError
            .noOptionalSupported
            .create(declaration, context, when: rawType.contains("?"))
        
        return [
            """
            get {
                let ctn = Container.shared
                if let instance = ctn.resolveOptional(\(raw: resolveType)\(raw: protocolType) scope: .shared) {
                    return instance
                } else {
                    let impl = \(raw: impl)
                    ctn.register(\(raw: protocolType)impl: impl)
                    return impl
                }
            }
            """
        ]
    }
}
