//
//  Instance.swift
//  ServiceAttach
//
//  Created by Jun on 12/29/25.
//

@attached(accessor, names: arbitrary)
public macro Instance() = #externalMacro(module: "ServiceAttachMacros", type: "InstanceMacro")


@attached(accessor, names: arbitrary)
public macro Instance(impl: Any.Type) = #externalMacro(module: "ServiceAttachMacros", type: "InstanceMacro")
