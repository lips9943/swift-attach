//
//  Attribute.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/23/26.
//

struct Attribute: Equatable {
    let name: String
    let arguments: [(name: String?, type: String)]
    
    static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        return lhs.name == rhs.name
    }
}
