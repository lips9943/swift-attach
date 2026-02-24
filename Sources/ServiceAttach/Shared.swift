//
//  Shared.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

@attached(accessor, names: arbitrary)
public macro Shared() = #externalMacro(module: "ServiceAttachMacros", type: "SharedMacro")

@attached(accessor, names: arbitrary)
public macro Shared(impl: AnyObject.Type) = #externalMacro(module: "ServiceAttachMacros", type: "SharedMacro")
