//
//  Helper.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

struct Helper {
    static func removeSelf(type: String) -> String {
        type.replacingOccurrences(of: ".self", with: "")
    }
    static func publicModify(declaration: some DeclGroupSyntax) -> String {
        return declaration.modifiers.contains { $0.name.text == "public" } ? "public " : ""
    }
    
    static func publicModify(declaration: some DeclSyntaxProtocol) -> String {
        if let cls = declaration.as(ClassDeclSyntax.self) {
            return publicModify(declaration: cls)
        } else if let strt = declaration.as(StructDeclSyntax.self) {
            return publicModify(declaration: strt)
        } else if let act = declaration.as(ActorDeclSyntax.self) {
            return publicModify(declaration: act)
        } else if let enu = declaration.as(EnumDeclSyntax.self) {
            return publicModify(declaration: enu)
        } else if let prtc = declaration.as(ProtocolDeclSyntax.self) {
            return publicModify(declaration: prtc)
        } else {
            return ""
        }
    }
    
    static func removeSpecialCharacters(_ text: String) -> String {
        let removeSet = CharacterSet(charactersIn: "!? ()")
        return text.components(separatedBy: removeSet).joined()
    }
    
    static func getArgsAsStrings(_ node: AttributeSyntax) -> [String]? {
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
        return args.map(\.expression.trimmedDescription).map({String($0.split(separator: ".")[0])})
    }
    
    static func getInheritedNames(node: AttributeSyntax, inheritanceClause: InheritanceClauseSyntax?) -> [String] {
        var result: [String] = []
        
        if let inherit = inheritanceClause?.inheritedTypes.map({$0.description.filter({!$0.isWhitespace})}) {
            guard let attr = node.arguments?
                .as(LabeledExprListSyntax.self)?
                .compactMap(\.expression.description)
                .map({String($0.split(separator: ".")[0])}) else { return result }
            for item in inherit {
                if attr.contains(where: { $0 == item }) {
                    result.append(item)
                }
            }
            return result
        }
        
        return result
    }
    
    static func removeDoubleQuotationMarks(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "")
    }
}
