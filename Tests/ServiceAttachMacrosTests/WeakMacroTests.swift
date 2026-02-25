import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class WeakMacroTests: XCTestCase {

    func testWeakMacro_Basic() throws {
        assertMacroExpansion(
            """
            @Weak(varName: "output")
            var interactor: Interactor!
            """,
            expandedSource: """
            var interactor: Interactor! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(Interactor.self,  scope: .weak) {
                        return instance
                    } else {
                        let impl = Interactor()
                        impl.output = self
                        ctn.register(impl: impl, scope: .weak)
                        return impl
                    }
                }
            }
            """,
            macros: ["Weak": WeakMacro.self]
        )
    }

    func testWeakMacro_WithProtocol() throws {
        assertMacroExpansion(
            """
            @Weak(varName: "view", protocols: PresenterProtocol.self)
            var presenter: Presenter!
            """,
            expandedSource: """
            var presenter: Presenter! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(PresenterProtocol.self, protocol: Presenter.self, scope: .weak) {
                        return instance
                    } else {
                        let impl = PresenterProtocol()
                        impl.view = self
                        ctn.register(protocol: Presenter.self, impl: impl, scope: .weak)
                        return impl
                    }
                }
            }
            """,
            macros: ["Weak": WeakMacro.self]
        )
    }
}
