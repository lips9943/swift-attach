//
//  FuncSyntax.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/19/26.
//

struct FuncSyntax {
    let name: String
    let returnType: String?
    let parameters: [(name: String, type: String)]
    let isThrowing: Bool
    let isAsync: Bool
    let attributes: [Attribute]
    let scope: ScopeSyntax
}
