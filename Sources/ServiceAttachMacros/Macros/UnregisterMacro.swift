//
//  UnregisterMacro.swift
//  ServiceAttach
//
//  Created by 고혁준 on 1/5/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UnregisterMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let types = node.arguments?
            .as(LabeledExprListSyntax.self)?
            .map(\.expression.trimmedDescription) else { return [] }

        var addingSyntax: String = ""
        for type in types {
            let fixedtypes = Helper.removeSpecialCharacters(type).split(separator: ",")
            MacroError.expressionRequired.create(declaration, context, when: fixedtypes.count != 2)
            guard let baseType = fixedtypes.first, let protocolType = fixedtypes.last else { return []}
            let fullSyntax = "Container.shared.unregister(type: \(baseType), protocol: \(protocolType))"
            addingSyntax.append(fullSyntax + "\n")
        }

        return [
            try .init(
            """
            extension \(type) {
                private func unregisterObjects() {
                    \(raw: addingSyntax)
                }
            }
            """
            )
        ]
    }
}
