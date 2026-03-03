//
//  ContainerErrorTests.swift
//  ServiceAttach
//
//  Created for macro quality refactoring
//

import XCTest
@testable import ServiceAttach

final class ContainerErrorTests: XCTestCase {

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
}
