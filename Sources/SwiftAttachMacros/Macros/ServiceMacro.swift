//
//  ServiceMacro.swift
//  SwiftAttach
//
//  Created by Jun on 5/3/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators
import Foundation

public struct ServiceMacro {
    
}

extension ServiceMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let members = SyntaxUtil.findMemberSyntaxsByBlock(from: declaration.memberBlock)
        
        // init 안에 들어갈 파라미터를 계산
        let parameters: [DeclSyntax] = members
            .compactMap { member in
                guard !member.attributes.contains(where: {$0.name == "Ignore"}),
                      member.type.contains("Service") || member.type.contains("Repository") else { return nil }
                let scope = member.attributes.contains(where: { $0.name == "Singleton" }) ? ".shared" : ".transient"
                if member.attributes.contains(where: { $0.name == "NonImplement" }) {
                    return "private lazy var _\(raw: member.name): \(raw: member.type)? = Container().resolveOptional(\(raw: member.type).self, scope: \(raw: scope))"
                } else if member.attributes.contains(where: { $0.name == "Named" }),
                          let firstValue = member.attributes.first,
                          let parameterValue = firstValue.arguments.first?.type {
                    return "private lazy var _\(raw: member.name): \(raw: member.type)? = Container().resolve(impl: \(raw: parameterValue), protocol: \(raw: member.type).self, scope: \(raw: scope))"
                } else {
                    return "private lazy var _\(raw: member.name): \(raw: member.type)? = Container().resolve(impl: \"\(raw: member.type)Impl\", protocol: \(raw: member.type).self, scope: \(raw: scope))"
                }
            }
        
        // 초기화에 들어갈 값이 없다면 []를 반환.
        guard !parameters.isEmpty else { return [] }
        
        return parameters
    }
}

extension ServiceMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // 변수 선언만 처리
        
        guard let variable = member.as(VariableDeclSyntax.self),
              let type = variable.bindings.first?.typeAnnotation?.type.trimmedDescription,
              type.contains("Service") || type.contains("Repository") else { return [] }
        
        for attribute in variable.attributes {
            if let att = attribute.as(AttributeSyntax.self),
               att.attributeName.trimmedDescription == "Ignore" {
                return []
            }
        }
        
        return [
            AttributeSyntax("@PropertyInjection")
        ]
    }
    
    
}


//extension ServiceMacro: ExtensionMacro {
//    public static func expansion(
//        of node: SwiftSyntax.AttributeSyntax,
//        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
//        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
//        conformingTo protocols: [SwiftSyntax.TypeSyntax],
//        in context: some SwiftSyntaxMacros.MacroExpansionContext
//    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
//        guard let objectType = SyntaxUtil.objectType(from: declaration) else { return [] }
//        let members = SyntaxUtil.collectStoredProperties(from: declaration.memberBlock)
//
//
//
//        return [
//            try .init(
//            """
//            extension \(raw: objectType.name): _RegisterContainer {
//                public static func _register(into container: Container) {
//
//                }
//            }
//            """
//            )
//        ]
//    }
//}

//extension ServiceMacro: PeerMacro {
//    public static func expansion(
//        of node: SwiftSyntax.AttributeSyntax,
//        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
//        in context: some SwiftSyntaxMacros.MacroExpansionContext
//    ) throws -> [SwiftSyntax.DeclSyntax] {
//        guard let objectType = SyntaxUtil.objectType(from: declaration),
//              let protocols = objectType.inheritType?.filter({ $0.contains("Service") }) else { return [] }
//
//        if protocols.isEmpty {
//            CompileErrorHandler.e(declaration, context, message: { "Protocol name must be suffix as 'Service' and can not found: \(protocols)" })
//        }
//
//        let factoryName = firstProtocol.map { "\($0)_Factory_Attach" } ?? "\(name)_Factory_Attach"
//        let returnType = firstProtocol ?? name
//
//        return [
//            """
//            public struct \(raw: factoryName) {
//                public static func instance() -> \(raw: returnType) {
//                    let i = \(raw: name)()
//                    return i
//                }
//            }
//            """
//        ]
//    }
//}
