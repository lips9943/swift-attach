//
//  ContainerErrorTests.swift
//  ServiceAttach
//
//  Created for macro quality refactoring
//

import XCTest
@testable import ServiceAttach

/// ContainerError 테스트
final class ContainerErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testContainerErrorTypeNotInitialized() {
        // 타입이 등록되지 않았을 때 에러가 발생하는지 확인
        let error = ContainerError.typeNotRegistered(type: "MyService", scope: ".transient")

        XCTAssertEqual(
            error.errorDescription,
            "Container에 등록되지 않은 타입입니다: MyService (scope: .transient)"
        )
    }

    func testContainerErrorConformsToError() {
        // Error 프로토콜 준수 확인
        let error: Error = ContainerError.typeNotRegistered(type: "TestType", scope: ".shared")

        XCTAssertNotNil(error as? ContainerError)
    }

    // MARK: - Throwing API Tests

    func testResolveUnregisteredTypeThrows() async {
        XCTAssertThrowsError(
            try Container.shared.resolve(UnregisteredService.self)
        ) { error in
            guard let containerError = error as? ContainerError else {
                XCTFail("Expected ContainerError")
                return
            }
            if case .typeNotRegistered(let type, let scope) = containerError {
                XCTAssertEqual(type, "UnregisteredService")
                XCTAssertEqual(scope, "transient")
            } else {
                XCTFail("Expected typeNotRegistered error")
            }
        }
    }

    func testResolveUnregisteredTypeWithSharedScopeThrows() async {
        XCTAssertThrowsError(
            try Container.shared.resolve(UnregisteredService.self, scope: .shared)
        ) { error in
            guard let containerError = error as? ContainerError else {
                XCTFail("Expected ContainerError")
                return
            }
            if case .typeNotRegistered(let type, let scope) = containerError {
                XCTAssertEqual(type, "UnregisteredService")
                XCTAssertEqual(scope, "shared")
            } else {
                XCTFail("Expected typeNotRegistered error")
            }
        }
    }

    func testResolveUnregisteredProtocolThrows() async {
        XCTAssertThrowsError(
            try Container.shared.resolve(UnregisteredService.self, protocol: UnregisterProtocol.self)
        ) { error in
            guard let containerError = error as? ContainerError else {
                XCTFail("Expected ContainerError")
                return
            }
            if case .typeNotRegistered(let type, let scope) = containerError {
                XCTAssertEqual(type, "UnregisteredService")
                XCTAssertEqual(scope, "transient")
            } else {
                XCTFail("Expected typeNotRegistered error")
            }
        }
    }

    // MARK: - Optional API Tests

    func testResolveOptionalReturnsNilForUnregistered() async {
        let result: UnregisteredService? = Container.shared.resolveOptional(UnregisteredService.self)
        XCTAssertNil(result, "등록되지 않은 타입은 nil을 반환해야 합니다")
    }

    func testResolveOptionalWithSharedScopeReturnsNilForUnregistered() async {
        let result: UnregisteredService? = Container.shared.resolveOptional(UnregisteredService.self, scope: .shared)
        XCTAssertNil(result, "등록되지 않은 타입은 nil을 반환해야 합니다")
    }

    // MARK: - Integration Tests

    func testResolveRegisteredTypeSucceeds() async {
        // 등록
        Container.shared.register(impl: TestService())

        // 정상 resolve
        let result: TestService? = Container.shared.resolveOptional(TestService.self)
        XCTAssertNotNil(result)

        // 정리
        Container.shared.clearAll()
    }

    func testThrowingResolveRegisteredTypeSucceeds() async throws {
        // 등록
        Container.shared.register(impl: TestService())

        // 정상 resolve
        let result: TestService = try Container.shared.resolve(TestService.self)
        XCTAssertNotNil(result)

        // 정리
        Container.shared.clearAll()
    }
}

// MARK: - Helper Types

private struct UnregisteredService {}

private protocol UnregisterProtocol {}

private struct TestService {}
