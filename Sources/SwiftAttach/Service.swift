//
//  Service.swift
//  SwiftAttach
//
//  Created by Jun on 5/3/26.
//

@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro Service() = #externalMacro(module: "SwiftAttachMacros", type: "ServiceMacro")
