//
//  AttachConfigMacro.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/19/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators
import Foundation

public struct AttachConfigMacro {
    
}

extension AttachConfigMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let funcSyntax = declaration.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map { SyntaxUtil.findFunctionSyntax(funcDecl: $0) }
            .compactMap {
                guard let returnType = $0.returnType else { return nil}
                return "container.register(protocol: \(returnType).self, impl: self.\($0.name)(), scope: .transient)"
            }.joined(separator: "\n")
        
        
        return [
            """
            @discardableResult
            init() {
                let container = SwiftAttach.Container()
                \(raw: funcSyntax)
            }
            """
        ]
    }
}
