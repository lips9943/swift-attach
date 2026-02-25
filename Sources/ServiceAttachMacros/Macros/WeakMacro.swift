//
//  WeekMacro.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct WeakMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // 어노테이션 가져오기.
        guard let args = node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .map(\.expression.trimmedDescription) else { return [] }
        
        
        // 메인 오브젝트 타입을 선언.
        guard var varName = args.first else { return [] }
        
        var implArg: String?
        if args.count > 1 {
            implArg = args[1]
        }
        
        // 변수 정보를 가져옴.
        guard let varSyntax = declaration.as(VariableDeclSyntax.self) else {
            MacroError
                .typeNotSupported
                .createDiagnostic(declaration, context);
            return []
        }
        
        // 한 개 이상의 변수가 올 때에 컴파일 에러를 줌.
        MacroError.onlyOneBindedPropertySupported
            .create(declaration, context,
                    when: varSyntax.bindings.count != 1)
        
        // ?, ! 등이 포함된 타입
        guard let rawType = varSyntax.bindings.first?.typeAnnotation?.type.trimmedDescription else { return [] }
        
        // ?, !을 없앤 클린한 타입
        let type = Helper.removeSpecialCharacters(rawType)
        var resolveType: String = ""
        var impl: String = ""
        var protocolType: String = ""
        
        // when implementation argument exsists
        if let implArg {
            let typeName = Helper.removeSelf(type: implArg)
            resolveType = type + ".self,"
            impl = "\(type)()"
            protocolType = "protocol: \(typeName).self,"
        } else {
            resolveType = type + ".self, "
            impl = "\(type)()"
        }
        
        return [
            """
            get {
                let ctn = Container.shared
                if let instance = ctn.resolveOptional(\(raw: resolveType)\(raw: protocolType) scope: .weak) {
                    return instance
                } else {
                    let impl = \(raw: impl)
                    impl.\(raw: Helper.removeDoubleQuotationMarks(varName)) = self
                    ctn.register(\(raw: protocolType)impl: impl, scope: .weak)
                    return impl
                }
            }
            """
        ]    }
}
//if let instance = ctn.resolveOptional(\(raw: resolveType)\(raw: protocolType) scope: .weak) {
//    return instance
//} else {
//    let impl = \(raw: impl)
//    ctn.register(\(raw: protocolType)impl: impl)
//    return impl
//}
