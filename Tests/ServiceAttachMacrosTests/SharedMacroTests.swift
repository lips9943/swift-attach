import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class SharedMacroTests: XCTestCase {

    func testSharedMacro_WithoutImpl() throws {
        assertMacroExpansion(
            """
            @Shared
            var service: MyService!
            """,
            expandedSource: """
            var service: MyService! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(MyService.self,  scope: .shared) {
                        return instance
                    } else {
                        let impl = MyService()
                        ctn.register(impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Shared": SharedMacro.self]
        )
    }

    func testSharedMacro_WithImpl() throws {
        assertMacroExpansion(
            """
            @Shared(impl: ServiceImpl.self)
            var service: ServiceProtocol!
            """,
            expandedSource: """
            var service: ServiceProtocol! {
                get {
                    let ctn = Container.shared
                    if let instance = ctn.resolveOptional(ServiceImpl.self, protocol: ServiceProtocol.self, scope: .shared) {
                        return instance
                    } else {
                        let impl = ServiceImpl()
                        ctn.register(protocol: ServiceProtocol.self, impl: impl)
                        return impl
                    }
                }
            }
            """,
            macros: ["Shared": SharedMacro.self]
        )
    }
}
