//
//  ContainerError.swift
//  ServiceAttach
//
//  Created for macro quality refactoring
//

import Foundation

/// Container에서 발생할 수 있는 에러 타입
public enum ContainerError: Error, LocalizedError {
    /// 타입이 컨테이너에 등록되지 않음
    case typeNotRegistered(type: String, scope: String)

    public var errorDescription: String? {
        switch self {
        case .typeNotRegistered(let type, let scope):
            return "Container에 등록되지 않은 타입입니다: \(type) (scope: \(scope))"
        }
    }
}
