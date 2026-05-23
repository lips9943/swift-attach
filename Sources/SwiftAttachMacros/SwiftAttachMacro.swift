import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


@main
struct SwiftAttachPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServiceMacro.self,
        PropertyInjectionMacro.self,
        AttachConfigMacro.self,
        
        // Non Functional Macros
        IgnoreMacro.self,
        NonImplementMacro.self,
        SingletonMacro.self,
        NamedMacro.self
    ]
}


struct CompileErrorHandler {
    static func e(_ decl: some SyntaxProtocol, _ context: some MacroExpansionContext, message: () -> String) {
        context.diagnose(
            Diagnostic(node: decl, message: MacroExpansionErrorMessage(message()))
        )
    }
}

