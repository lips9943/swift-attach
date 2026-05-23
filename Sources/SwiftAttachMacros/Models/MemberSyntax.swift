//
//  MemberSyntax.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/17/26.
//

struct MemberSyntax {
    let name: String
    let type: String
    let attributes: [Attribute]
    let scope: ScopeSyntax
    let isOptional: Bool
    let isImplicitlyUnwrappedOptional: Bool
}
