//
//  Singleton.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/20/26.
//

@attached(peer)
public macro Singleton() = #externalMacro(module: "SwiftAttachMacros", type: "SingletonMacro")
