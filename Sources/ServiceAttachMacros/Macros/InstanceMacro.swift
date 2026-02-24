//
//  InstanceMacro.swift
//  ServiceAttach
//
//  Created by Jun on 12/29/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators

public struct InstanceMacro: AccessorMacro {
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
            
                if let instance = ctn.resolveOptional(\(raw: resolveType)\(raw: protocolType) scope: .transient) {
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
