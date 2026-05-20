//
//  ScopeSyntax.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/17/26.
//

struct ScopeSyntax: Equatable {
    let isWeak: Bool
    let isLazy: Bool
    let isFinal: Bool
    let isStatic: Bool
    let scope: ScopeType
}

enum ScopeType: String, Equatable {
    case `private` = "private"
    case `internal` = "internal"
    case `public` = "public"
    case `open` = "open"
    case none = ""
}
