//
//  NamedMacro.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/23/26.
//
import SwiftSyntaxMacros
import SwiftSyntax

public struct NamedMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}


