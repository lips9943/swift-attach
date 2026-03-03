import XCTest
@testable import ServiceAttach

/// 스레드 안전성과 동시성 관련 테스트
final class ConcurrencyTests: XCTestCase {

    // MARK: - Concurrent Resolve Tests

    func testConcurrentResolve() async throws {
        // Given: 테스트 서비스 등록
        Container.shared.register(impl: TestService(), scope: .transient)

        // When: 100개의 동시 resolve 호출
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let result: TestService? = Container.shared.resolveOptional(TestService.self, scope: .transient)
                    XCTAssertNotNil(result, "resolve는 nil을 반환하면 안 됩니다")
                }
            }
        }

        // Then: 데이터 레이스 없이 완료되어야 함 (테스트 통과로 확인)
    }

    func testConcurrentResolveWithSharedScope() async throws {
        // Given: shared 스코프로 테스트 서비스 등록
        Container.shared.register(impl: SharedTestService(), scope: .shared)

        // When: 100개의 동시 resolve 호출
        var resolvedInstances: [SharedTestService] = []
        await withTaskGroup(of: SharedTestService?.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return Container.shared.resolveOptional(SharedTestService.self, scope: .shared)
                }
            }

            for await result in group {
                if let instance = result {
                    resolvedInstances.append(instance)
                }
            }
        }

        // Then: 모든 인스턴스가 동일한 싱글톤이어야 함
        XCTAssertEqual(resolvedInstances.count, 100)
        let firstInstance = resolvedInstances.first
        for instance in resolvedInstances {
            XCTAssertTrue(
                firstInstance === instance,
                "shared 스코프는 모두 동일한 인스턴스를 반환해야 합니다"
            )
        }
    }

    func testConcurrentRegisterAndResolve() async throws {
        // When: 동시에 등록과 resolve 수행
        await withTaskGroup(of: Void.self) { group in
            // 등록 작업
            for i in 0..<50 {
                group.addTask {
                    let _ = "Service_\(i)"
                    Container.shared.register(impl: TestService(), scope: .transient)
                }
            }

            // resolve 작업
            for _ in 0..<50 {
                group.addTask {
                    let _: TestService? = Container.shared.resolveOptional(TestService.self, scope: .transient)
                }
            }
        }

        // Then: 데이터 레이스 없이 완료되어야 함
    }

    // MARK: - Thread Safety Tests

    func testThreadSafeRegister() throws {
        // Given: 여러 스레드에서 동시에 등록
        let expectation = expectation(description: "모든 등록 완료")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            let _ = "ThreadService_\(i)"
            Container.shared.register(impl: TestService(), scope: .transient)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testThreadSafeResolve() throws {
        // Given: 서비스 등록 (class 타입 사용)
        Container.shared.register(impl: TestServiceClass(), scope: .shared)

        // When & Then: 여러 스레드에서 동시에 resolve
        let expectation = expectation(description: "모든 resolve 완료")
        expectation.expectedFulfillmentCount = 100

        var instances: [TestServiceClass] = []
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            if let instance: TestServiceClass = Container.shared.resolveOptional(TestServiceClass.self, scope: .shared) {
                lock.lock()
                instances.append(instance)
                lock.unlock()
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // 모든 인스턴스가 동일한 싱글톤이어야 함
        XCTAssertEqual(instances.count, 100)
        let firstInstance = instances.first
        for instance in instances {
            XCTAssertTrue(
                firstInstance === instance,
                "shared 스코프는 thread-safe하게 동일한 인스턴스를 반환해야 합니다"
            )
        }
    }

    // MARK: - Actor Isolation Tests

    func testContainerSharedIsSingleton() async {
        // Container.shared는 항상 동일한 인스턴스여야 함
        let container1 = Container.shared
        let container2 = Container.shared

        // actor이지만 static shared는 동일한 인스턴스
        XCTAssertTrue(
            container1 === container2,
            "Container.shared는 싱글톤이어야 합니다"
        )
    }

    func testNonisolatedMethodsWorkWithoutAwait() {
        // nonisolated 메서드는 await 없이 호출 가능
        Container.shared.register(impl: TestService(), scope: .transient)
        let result: TestService? = Container.shared.resolveOptional(TestService.self, scope: .transient)

        XCTAssertNotNil(result, "nonisolated 메서드는 await 없이 호출 가능해야 합니다")
    }

    // MARK: - Edge Cases

    func testConcurrentWeakScopeResolve() async throws {
        // Given: weak 스코프로 서비스 등록
        Container.shared.register(impl: WeakTestService(), scope: .weak)

        // When: 약한 참조가 해제되지 않는 동안 여러 번 resolve
        var resolvedInstances: [WeakTestService] = []
        await withTaskGroup(of: WeakTestService?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return Container.shared.resolveOptional(WeakTestService.self, scope: .weak)
                }
            }

            for await result in group {
                if let instance = result {
                    resolvedInstances.append(instance)
                }
            }
        }

        // Then: weak 스코프에서도 안전하게 resolve되어야 함
        XCTAssertTrue(resolvedInstances.count > 0, "weak 스코프 resolve가 작동해야 합니다")
    }
}

// MARK: - Test Services

private struct TestService: Sendable {}
private final class TestServiceClass: @unchecked Sendable {}
private final class SharedTestService: @unchecked Sendable, Equatable {
    static func == (lhs: SharedTestService, rhs: SharedTestService) -> Bool {
        return lhs === rhs
    }
}
private final class WeakTestService: @unchecked Sendable {}
