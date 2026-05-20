//
//  PropertyInjectionMacro.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/19/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators
import Foundation

public struct PropertyInjectionMacro {
    
}


extension PropertyInjectionMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return [] }
        guard let member = SyntaxUtil.findMemberSyntax(varDecl: varDecl) else { return [] }
        
        if !member.isOptional && !member.isImplicitlyUnwrappedOptional {
            CompileErrorHandler.e(declaration, context) {
                "\'?\' or \'!\' is required."
            }
        }
        
//        guard !member.attributes.contains(where: {$0 == "Ignore"}) else { return [] }
        return [
            """
            get { _\(raw: member.name) }
            """
        ]
    }
    
    
}
