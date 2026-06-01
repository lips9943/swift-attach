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
                guard let returnType = $0.returnType else { return nil }
                if $0.attributes.contains(where: {$0.name == "NonImplement"}) {
                    return "container.register(impl: \($0.name)(), scope: .transient)"
                } else if $0.attributes.contains(where: { $0.name == "Named" }),
                          let firstValue = $0.attributes.first,
                          let parameterValue = firstValue.arguments.first?.type {
                    
                    return "container.register(customKey: \(parameterValue), protocol: (\(returnType)).self, impl: \($0.name)(), scope: .transient)"
                } else {
                    return "container.register(customKey: \"\(SyntaxUtil.eraseExpr(from: returnType))Impl\", protocol: (\(returnType)).self, impl: \($0.name)(), scope: .transient)"
                }
            }.joined(separator: "\n")
        
        
        return [
            """
            @discardableResult
            public init() {
                let container = SwiftAttach.Container()
                \(raw: funcSyntax)
            }
            """
        ]
    }
}
