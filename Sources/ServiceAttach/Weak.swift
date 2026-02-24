//
//  Week.swift
//  ServiceAttach
//
//  Created by 고혁준 on 12/31/25.
//

@attached(accessor, names: arbitrary)
public macro Weak(varName: String) = #externalMacro(module: "ServiceAttachMacros", type: "WeakMacro")

@attached(accessor, names: arbitrary)
public macro Weak(varName: String, protocols: AnyObject.Type) = #externalMacro(module: "ServiceAttachMacros", type: "WeakMacro")
