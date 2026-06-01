//
//  SyntaxUtil.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/17/26.
//
import SwiftSyntax

struct SyntaxUtil {
    static func objectType(
        from declaration: some DeclSyntaxProtocol
    ) -> ObjectSyntax? {
        if let decl = declaration.as(StructDeclSyntax.self) {
            let inheritType = decl.inheritanceClause?.inheritedTypes.compactMap { $0.type.trimmedDescription }
            let scope = scopesFromModifiers(decl.modifiers)
            return ObjectSyntax(name: decl.name.text, inheritType: inheritType, type: .struct, scope: scope)
        } else if let decl = declaration.as(ClassDeclSyntax.self) {
            let inheritType = decl.inheritanceClause?.inheritedTypes.compactMap { $0.type.trimmedDescription }
            let scope = scopesFromModifiers(decl.modifiers)
            return ObjectSyntax(name: decl.name.text, inheritType: inheritType, type: .class, scope: scope)
        } else if let decl = declaration.as(ActorDeclSyntax.self) {
            let inheritType = decl.inheritanceClause?.inheritedTypes.compactMap { $0.type.trimmedDescription }
            let scope = scopesFromModifiers(decl.modifiers)
            return ObjectSyntax(name: decl.name.text, inheritType: inheritType, type: .actor, scope: scope)
        } else if let decl = declaration.as(ProtocolDeclSyntax.self) {
            let inheritType = decl.inheritanceClause?.inheritedTypes.compactMap { $0.type.trimmedDescription }
            let scope = scopesFromModifiers(decl.modifiers)
            return ObjectSyntax(name: decl.name.text, inheritType: inheritType, type: .protocol, scope: scope)
        } else if let decl = declaration.as(EnumDeclSyntax.self) {
            let inheritType = decl.inheritanceClause?.inheritedTypes.compactMap { $0.type.trimmedDescription }
            let scope = scopesFromModifiers(decl.modifiers)
            return ObjectSyntax(name: decl.name.text, inheritType: inheritType, type: .enum, scope: scope)
        } else {
            return nil
        }
    }
    
    static func findMemberSyntaxsByBlock(
        from memberBlock: MemberBlockSyntax
    ) -> [MemberSyntax] {
        var result: [MemberSyntax] = []
        for member in memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let memberSyntax = findMemberSyntax(varDecl: varDecl) else { continue }
            
            result.append(memberSyntax)
        }
        
        return result
    }
    
    static func findMemberSyntax(varDecl: VariableDeclSyntax) -> MemberSyntax? {
        let scope = scopesFromModifiers(varDecl.modifiers)
        
        let bindings = varDecl.bindings
        
        guard let binding = bindings.first,
              let type = binding.typeAnnotation?.type,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
        
        var typeName = type.trimmedDescription
        if let optionalType = type.as(OptionalTypeSyntax.self)?.wrappedType.trimmedDescription {
            typeName = optionalType
        }
        
        if let iuoType = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.trimmedDescription {
            typeName = iuoType
        }
        
        // 매크로
        let attributes = varDecl.attributes
            .compactMap { $0.as(AttributeSyntax.self)}
            .map {
                let name = $0.attributeName.trimmedDescription
                guard let list = $0.arguments?.as(LabeledExprListSyntax.self) else { return Attribute(name: name, arguments: []) }
                
                var arguments: [(String?, String)] = []
                for argument in list {
                    arguments.append((argument.label?.text, argument.expression.trimmedDescription))
                }
                
                return Attribute(name: name, arguments: arguments)
            }
        
        return MemberSyntax(
            name: name,
            type: typeName,
            attributes: attributes,
            scope: scope,
            isOptional: type.is(OptionalTypeSyntax.self),
            isImplicitlyUnwrappedOptional: type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        )
    }
    
    static func findFunctionSyntax(funcDecl: FunctionDeclSyntax) -> FuncSyntax {
        let name = funcDecl.name.text
        let returnType = funcDecl.signature.returnClause?.type.trimmedDescription
            .replacingOccurrences(of: "any", with: "")
            .replacingOccurrences(of: " ", with: "")
        let params = funcDecl.signature.parameterClause.parameters.map { (name: $0.firstName.text, type: $0.type.trimmedDescription) }
        let isThrowing = funcDecl.signature.effectSpecifiers?.throwsClause != nil
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let scope = scopesFromModifiers(funcDecl.modifiers)
        let atrributes: [Attribute] = funcDecl.attributes
            .compactMap { $0.as(AttributeSyntax.self)}
            .map {
                let name = $0.attributeName.trimmedDescription
                guard let list = $0.arguments?.as(LabeledExprListSyntax.self) else { return Attribute(name: name, arguments: []) }
                
                var arguments: [(String?, String)] = []
                for argument in list {
                    arguments.append((argument.label?.text, argument.expression.trimmedDescription))
                }
                
                return Attribute(name: name, arguments: arguments)
            }
        return .init(name: name, returnType: returnType, parameters: params, isThrowing: isThrowing, isAsync: isAsync, attributes: atrributes, scope: scope)
    }
    
    static func scopesFromModifiers(_ modifiers: DeclModifierListSyntax) -> ScopeSyntax {
        var isWeak: Bool = false
        var isLazy: Bool = false
        var isFinal: Bool = false
        var isStatic: Bool = false
        
        var scope: ScopeType = .none
        
        for modifier in modifiers {
            switch modifier.name.text {
            case "private", "open", "public", "internal":
                guard let s = ScopeType(rawValue: modifier.name.text) else { continue }
                scope = s
            case "weak": isWeak = true
            case "lazy": isLazy = true
            case "final": isFinal = true
            case "static": isStatic = true
            default: continue
            }
        }
        
        return .init(isWeak: isWeak, isLazy: isLazy, isFinal: isFinal, isStatic: isStatic, scope: scope)
    }
}
