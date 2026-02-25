import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class InstanceMacroTests: XCTestCase {

    func testInstanceMacro_WithoutImpl() throws {
        assertMacroExpansion(
            """
            @Instance
            var service: MyService!
            """,
            expandedSource: """
            var service: MyService! {
                get {
                    let ctn = Container.shared

                    if let instance = ctn.resolveOptional(MyService.self,  scope: .transient) {
                        return instance
                    } else {
                        let impl = MyService()
                        ctn.register(impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Instance": InstanceMacro.self]
        )
    }

    func testInstanceMacro_WithImpl() throws {
        assertMacroExpansion(
            """
            @Instance(impl: ServiceImpl.self)
            var service: ServiceProtocol!
            """,
            expandedSource: """
            var service: ServiceProtocol! {
                get {
                    let ctn = Container.shared

                    if let instance = ctn.resolveOptional(ServiceImpl.self, protocol: ServiceProtocol.self, scope: .transient) {
                        return instance
                    } else {
                        let impl = ServiceImpl()
                        ctn.register(protocol: ServiceProtocol.self, impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Instance": InstanceMacro.self]
        )
    }
}
