//
//  ErrorTests.swift
//  ServiceAttachClient
//
//  Created by Claude on 2/26/26.
//
//  이 파일은 @Lazy 매크로의 에러 핸들링을 테스트합니다.
//  각 에러 케이스는 주석 처리되어 있으며, 테스트 시 주석을 해제하여
//  컴파일 타임에 올바른 에러 메시지가 출력되는지 확인할 수 있습니다.
//

import ServiceAttach
import Foundation

// MARK: - @Lazy Macro Error Handling Tests
//
// 아래 테스트 케이스들은 컴파일 에러가 발생해야 하는 코드들입니다.
// 각 테스트를 수행하려면 해당 코드의 주석을 해제하고 `swift build`를 실행하세요.

// ============================================
// ERROR TEST 1: 옵셔널 타입 미지원
// ============================================
// 예상 에러 메시지: "옵셔널 프로퍼티는 지원하지 않습니다."
//
// 주석 해제 후 빌드:
// swift build
//
// ❌ 에러: 옵셔널 타입 미지원
// @Lazy
// var optionalService: TestLazyService?

// ============================================
// ERROR TEST 2: 여러 프로퍼티 바인딩 미지원
// ============================================
// 예상 에러 메시지: "한가지 프로퍼티만 주입받을 수 있습니다."
//
// 주석 해제 후 빌드:
// swift build
//
// ❌ 에러: 여러 프로퍼티 바인딩 미지원
// @Lazy
// var x, y: Int

// ============================================
// ERROR TEST 3: 타입 애노테이션 누락
// ============================================
// 예상 동작: 컴파일 에러가 발생하거나 매크로 확장이 수행되지 않음
// 현재 구현에서는 타입 애노테이션이 없는 경우 빈 배열을 반환하여
// 매크로 확장이 일어나지 않습니다.
//
// 주석 해제 후 빌드:
// swift build
//
// ❌ 에러: 타입 애노테이션 누락
// @Lazy
// var noType = TestLazyService()

// ============================================
// ERROR TEST 4: 옵셔널 프로토콜 타입 미지원
// ============================================
// 예상 에러 메시지: "옵셔널 프로퍼티는 지원하지 않습니다."
//
// 주석 해제 후 빌드:
// swift build
//
// ❌ 에러: 옵셔널 프로토콜 타입 미지원
// @Lazy(impl: TestLazyImpl.self)
// var optionalProtocolService: TestLazyProtocol?

// ============================================
// ERROR TEST 5: 암시적 언래핑 옵셔널 (정상 동작)
// ============================================
// 참고: 암시적 언래핑 옵셔널(!)은 @Lazy에서 정상적으로 지원됩니다.
// 이는 실제로 옵셔널 체이닝(?과 같이)이 아니므로 lazy 패턴에 적합합니다.
//
// ✅ 정상: 암시적 언래핑 옵셔널은 지원됨
// @Lazy
// var implicitlyUnwrapped: TestLazyService!

// MARK: - 에러 테스트 실행 방법
//
// 1. 위 에러 케이스 중 하나를 선택합니다.
// 2. 해당 코드 블록의 주석을 모두 해제합니다.
// 3. 터미널에서 `swift build`를 실행합니다.
// 4. 예상 에러 메시지가 출력되는지 확인합니다.
// 5. 확인 후 다시 주석 처리하고 다음 케이스를 테스트합니다.
//
// 예시:
// ```
// $ swift build
// Building complete!
// ...
// error: @Lazy는 옵셔널 프로퍼티는 지원하지 않습니다.
//    --> .../ErrorTests.swift:39:1
// 37  | // ❌ 에러: 옵셔널 타입 미지원
// 38  | @Lazy
// 39  | var optionalService: TestLazyService?
//     | `- error: ...
// ```

// MARK: - 정상 동작 참고용
//
// 아래는 정상적으로 동작하는 코드입니다 (에러 테스트와 비교용)
//
// ✅ 정상: 기본 lazy 초기화
// @Lazy
// var normalService: TestLazyService!
//
// ✅ 정상: 프로토콜 타입 lazy
// @Lazy(impl: TestLazyImpl.self)
// var normalProtocolService: TestLazyProtocol!
