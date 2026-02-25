import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class UnregisterMacroTests: XCTestCase {

    func testUnregisterMacro_SingleType() throws {
        assertMacroExpansion(
            """
            @Unregister(type: (Presenter.self, nil))
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }
            """,
            expandedSource: """
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }

            extension View {
                private func unregisterObjects() {
                    Container.shared.unregister(type: Presenter.self, protocol: nil)

                }
            }
            """,
            macros: ["Unregister": UnregisterMacro.self]
        )
    }

    func testUnregisterMacro_MultipleTypes() throws {
        assertMacroExpansion(
            """
            @Unregister(type: (Presenter.self, nil), (Router.self, nil))
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }
            """,
            expandedSource: """
            class MyView {
                deinit {
                    unregisterObjects()
                }
            }

            extension View {
                private func unregisterObjects() {
                    Container.shared.unregister(type: Presenter.self, protocol: nil)
                    Container.shared.unregister(type: Router.self, protocol: nil)

                }
            }
            """,
            macros: ["Unregister": UnregisterMacro.self]
        )
    }
}
