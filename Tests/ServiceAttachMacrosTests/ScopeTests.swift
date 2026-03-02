import XCTest
@testable import ServiceAttach

final class ScopeTests: XCTestCase {

    func testScopeEnumValues() {
        // Scope enum이 세 가지 케이스를 가지는지 확인
        let allScopes: [Scope] = [.transient, .shared, .weak]

        XCTAssertEqual(allScopes.count, 3, "Scope should have exactly 3 cases")
    }

    func testScopeEquality() {
        // 동일한 scope는 같아야 함
        XCTAssertEqual(Scope.transient, Scope.transient)
        XCTAssertEqual(Scope.shared, Scope.shared)
        XCTAssertEqual(Scope.weak, Scope.weak)

        // 다른 scope는 달라야 함
        XCTAssertNotEqual(Scope.transient, Scope.shared)
        XCTAssertNotEqual(Scope.transient, Scope.weak)
        XCTAssertNotEqual(Scope.shared, Scope.weak)
    }

    func testScopeInContainer() {
        // Scope가 Container에서 올바르게 작동하는지 확인
        class TestService {}
        let container = Container()

        // transient scope
        container.register(impl: TestService(), scope: .transient)
        let transientResolved: TestService? = container.resolveOptional(TestService.self, scope: .transient)
        XCTAssertNotNil(transientResolved, "Transient scope should resolve")

        // shared scope
        container.register(impl: TestService(), scope: .shared)
        let sharedResolved1: TestService? = container.resolveOptional(TestService.self, scope: .shared)
        let sharedResolved2: TestService? = container.resolveOptional(TestService.self, scope: .shared)
        XCTAssertNotNil(sharedResolved1, "Shared scope should resolve")
        XCTAssertTrue(sharedResolved1 === sharedResolved2, "Shared scope should return same instance")

        // weak scope
        class WeakTestService: AnyObject {}
        let weakService = WeakTestService()
        container.register(impl: weakService, scope: .weak)
        let weakResolved: WeakTestService? = container.resolveOptional(WeakTestService.self, scope: .weak)
        XCTAssertNotNil(weakResolved, "Weak scope should resolve")
    }
}
