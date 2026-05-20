//
//  IgnoreMacro.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/20/26.
//

import SwiftSyntaxMacros
import SwiftSyntax

public struct IgnoreMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}
