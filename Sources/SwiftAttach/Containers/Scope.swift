//
//  Scope.swift
//  Injective
//
//  Created by Jun on 12/26/25.
//

/// 인스턴스의 생명주기(스코프)를 정의합니다.
///
/// 스코프는 인스턴스가 얼마나 오래 유지되는지 결정합니다.
public enum Scope {
    /// 매번 새 인스턴스를 생성합니다.
    case transient

    /// 앱 전체에서 공유되는 싱글톤 인스턴스입니다.
    case shared

    /// weak 참조로 관리되는 인스턴스입니다.
    case weak
}
