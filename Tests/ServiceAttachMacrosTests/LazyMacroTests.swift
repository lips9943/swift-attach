import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ServiceAttachMacros

final class LazyMacroTests: XCTestCase {

    func testLazyMacro_WithoutImpl() throws {
        assertMacroExpansion(
            """
            @Lazy
            var service: MyService
            """,
            expandedSource: """
            var service: MyService {
                get {
                    let ctn = Container.shared

                    if let instance = ctn.resolveOptional(MyService.self,  scope: .weak) {
                        return instance
                    } else {
                        let impl = MyService()
                        ctn.register( impl: impl, scope: .weak)
                        return impl
                    }
                }
            }
            """,
            macros: ["Lazy": LazyMacro.self]
        )
    }

    func testLazyMacro_WithImpl() throws {
        assertMacroExpansion(
            """
            @Lazy(impl: ServiceImpl.self)
            var service: ServiceProtocol
            """,
            expandedSource: """
            var service: ServiceProtocol {
                get {
                    let ctn = Container.shared

                    if let instance = ctn.resolveOptional(ServiceImpl.self, protocol: ServiceProtocol.self, scope: .weak) {
                        return instance
                    } else {
                        let impl = ServiceImpl()
                        ctn.register(protocol: ServiceProtocol.self, impl: impl, scope: .weak)
                        return impl
                    }
                }
            }
            """,
            macros: ["Lazy": LazyMacro.self]
        )
    }

    func testLazyMacro_OptionalNotSupported() throws {
        // TODO: diagnostics API 확인 필요
        // 현재 swift-syntax 버전에서 diagnostics 파라미터 형식을 확인해야 함
    }
}
