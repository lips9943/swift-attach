//
//  Named.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/23/26.
//

/// A marker macro used to register or resolve a dependency with a custom key name.
///
/// When applied to a method in `@AttachConfig`, the returned instance is registered in the DI container with the specified custom key.
/// When applied to a property in `@Service`, the dependency is resolved from the DI container using the specified custom key instead of the default `[Type]Impl` convention.
///
/// - Parameter type: The custom key string used for registration and resolution.
@attached(peer)
public macro Named(_ type: String) = #externalMacro(module: "SwiftAttachMacros", type: "NamedMacro")
