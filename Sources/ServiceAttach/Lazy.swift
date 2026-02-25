//
//  Lazy.swift
//  ServiceAttach
//
//  Created by Claude on 2/26/26.
//

@attached(accessor, names: arbitrary)
public macro Lazy() = #externalMacro(module: "ServiceAttachMacros", type: "LazyMacro")

@attached(accessor, names: arbitrary)
public macro Lazy(impl: Any.Type) = #externalMacro(module: "ServiceAttachMacros", type: "LazyMacro")
