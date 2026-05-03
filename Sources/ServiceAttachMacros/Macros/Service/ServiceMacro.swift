//
//  ServiceMacro.swift
//  ServiceAttach
//
//  Created by Jun on 5/3/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators

public struct ServiceMacro: PeerMacro, MemberMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let (name, inheritanceClause) = extractInfo(from: declaration) else { return [] }

        let firstProtocol = inheritanceClause?
            .inheritedTypes.first?.type.trimmedDescription

        let factoryName = firstProtocol.map { "\($0)_Factory" } ?? "\(name)_Factory"
        let returnType = firstProtocol ?? name

        return [
            """
            public struct \(raw: factoryName) {
                public static func instance() -> \(raw: returnType) {
                    let i = \(raw: name)()
                    return i
                }
            }
            """
        ]
    }

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let properties = collectStoredProperties(from: declaration.memberBlock)
        guard !properties.isEmpty else { return [] }

        let params = properties
            .map { "\($0.name): \($0.type) = \($0.type)_Factory.instance()" }
            .joined(separator: ", ")
        let body = properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n")

        return [
            """
            public init(\(raw: params)) {
                \(raw: body)
            }
            """
        ]
    }

    private static func extractInfo(
        from declaration: some SwiftSyntax.DeclSyntaxProtocol
    ) -> (name: String, inheritanceClause: InheritanceClauseSyntax?)? {
        if let decl = declaration.as(StructDeclSyntax.self) {
            return (decl.name.text, decl.inheritanceClause)
        } else if let decl = declaration.as(ClassDeclSyntax.self) {
            return (decl.name.text, decl.inheritanceClause)
        } else if let decl = declaration.as(ActorDeclSyntax.self) {
            return (decl.name.text, decl.inheritanceClause)
        }
        return nil
    }

    private static func collectStoredProperties(
        from memberBlock: MemberBlockSyntax
    ) -> [(name: String, type: String)] {
        memberBlock.members.compactMap { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  binding.initializer == nil,
                  binding.accessorBlock == nil,
                  let typeAnnotation = binding.typeAnnotation,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
            else { return nil }
            return (identifier.identifier.text, typeAnnotation.type.trimmedDescription)
        }
    }
}
