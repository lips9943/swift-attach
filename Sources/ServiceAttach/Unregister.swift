//
//  Unregister.swift
//  ServiceAttach
//
//  Created by 고혁준 on 1/5/26.
//


@attached(extension, names: arbitrary)
public macro Unregister(type: (Any.Type, Any.Type?)...) = #externalMacro(module: "ServiceAttachMacros", type: "UnregisterMacro")
