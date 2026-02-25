//
//  LazyMacro.swift
//  ServiceAttach
//
//  Created by Claude on 2/26/26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftOperators

public struct LazyMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // 구현은 다음 단계에서
        return []
    }
}
