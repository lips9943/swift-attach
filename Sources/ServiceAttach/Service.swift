//
//  Service.swift
//  ServiceAttach
//
//  Created by Jun on 5/3/26.
//

@attached(peer)
@attached(member)
public macro Service() = #externalMacro(module: "ServiceAttachMacros", type: "ServiceMacro")
