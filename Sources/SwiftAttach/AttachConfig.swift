//
//  AttachConfig.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/19/26.
//

@attached(member, names: named(init))
public macro AttachConfig() = #externalMacro(module: "SwiftAttachMacros", type: "AttachConfigMacro")
