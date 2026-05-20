//
//  SyntaxType.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/17/26.
//

struct ObjectSyntax {
    let name: String
    let inheritType: [String]?
    let type: ObjectType
    let scope: ScopeSyntax
}


enum ObjectType {
    case `class`
    case `struct`
    case `protocol`
    case `enum`
    case `actor`
}
