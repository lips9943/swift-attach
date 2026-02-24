import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


@main
struct ServiceAttachPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InstanceMacro.self,
        SharedMacro.self,
        WeakMacro.self,
        UnregisterMacro.self
    ]
}


struct CompileErrorHandler {
    static func e(_ decl: some SyntaxProtocol, _ context: some MacroExpansionContext, message: () -> String) {
        context.diagnose(
            Diagnostic(node: decl, message: MacroExpansionErrorMessage(message()))
        )
    }
}

