//
//  PropertyInjection.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/19/26.
//

@attached(accessor)
public macro PropertyInjection() = #externalMacro(module: "SwiftAttachMacros", type: "PropertyInjectionMacro")
