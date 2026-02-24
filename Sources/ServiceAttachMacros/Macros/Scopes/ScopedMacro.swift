//
//  ScopedMacro.swift
//  ServiceAttach
//
//  Created by Jun on 1/4/26.
//


// scoped: 새로운 컨테이너 생성, 스코프 안에서 객체를 생성하고, 해당 스코프가 삭제될 때 모든 객체를 삭제.

// Rules:
// 1. transient만 사용 가능.
// 2.


/// 구현해야할 내용
/// 1. 객체 안에 private 컨테이너를 생성.
/// 2. 매개변수들의 어노테이션을 확인하고, ScopeProperty에 해당되는 값에 getter로 Container 안에 저장. 그리고 불러오기.
/// 3.
///
///
///
/// 문제 1: 컨테이너를 다음 스코프로 이동 시킬 때 문제 발생.
