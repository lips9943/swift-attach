import ServiceAttach
import Foundation

/// 구현해야할 3가지
/// 1. scope 안에서 공유되는 객체
/// 2. weak를 이용한 자동으로 메모리가 해제되는 객체
/// 3.






class Service {

}

class Repository {
    // factory
    @Instance
    var service: Service!
}

class Usecase {
    // factory
    @Instance
    var repo: Repository!
}

class Router {
    static func present() -> View {
        return View()
    }

    func detailView(from view: DetailFix) -> DetailView {
        let result = DetailView()
        result.fix = view

        return result
    }
}

class Interactor {
    @Instance
    var usecase: Usecase!

    @Shared
    var usecase2: Usecase!


    weak var output: PresenterOutput?
}

protocol PresenterOutput: AnyObject {
    func done(v: String)
}

// unregister
class Presenter: PresenterOutput {
    weak var view: ViewP?

    @Weak(varName: "output")
    var interactor: Interactor!

    @Instance
    var router: Router!

    deinit {
        Container.shared.unregister(type: Interactor.self, protocol: nil)
        Container.shared.unregister(type: Router.self, protocol: nil)
    }

    func done(v: String) {
        view?.doable(v: v)

    }
}

protocol ViewP: AnyObject {
    func doable(v: String)
}

var sss: String = "seq"
@Unregister(type: (Presenter.self, nil), (Presenter.self, nil))
class View: ViewP, DetailFix {
    @Weak(varName: "view")
    var presenter: Presenter!

    func doable(v: String) {

    }

    deinit {
        unregisterObjects()
    }

    func fix(name: String) {

    }
}

protocol RemoveRelativeObjectInView {
    init(container: Container)
}


extension View {

}

protocol DetailFix: AnyObject {
    func fix(name: String)
}

class DetailView {
    weak var fix: DetailFix?
}

struct Entity {
    var name: String
    init() {
        self.name = "안녕"
    }
}


class A {
    var text:String = "123"
}

class B {
    var text:String = "456"
}
@Unregister(type: (A.self, nil))
class Test {
    @Shared
    var a: A
//
//    var b: B
    deinit {
        unregisterObjects()
    }
}

// MARK: - @Lazy Macro Tests

// MARK: - @Lazy Macro Tests

// 테스트용 클래스
final class TestLazyService {
    var name: String
    var initCount: Int = 0

    init(name: String = "default") {
        self.name = name
        self.initCount += 1
        print("TestLazyService initialized: \(name)")
    }
}

// 프로토콜은 AnyObject를 상속받아야 weak 참조 가능
protocol TestLazyProtocol: AnyObject {
    var protocolName: String { get }
}

final class TestLazyImpl: TestLazyProtocol {
    var protocolName: String = "TestLazyImpl"
    var initCount: Int = 0

    init() {
        self.initCount += 1
        print("TestLazyImpl initialized")
    }
}

// 테스트를 별도 클래스로 캡슐화하여 MainActor 문제 회피
@Unregister(type: (TestLazyService.self, nil), (TestLazyProtocol.self, nil))
final class LazyTests {
    // 기본 lazy 초기화 테스트
    @Lazy
    var lazyService: TestLazyService!

    // 프로토콜 타입 lazy 테스트
    @Lazy(impl: TestLazyImpl.self)
    var lazyProtocolService: TestLazyProtocol!

    func runAllTests() {
        testBasicLazy()
        testLazyWithProtocol()
        testLazyMemoryManagement()
    }

    private func testBasicLazy() {
        print("=== Test: Basic Lazy Initialization ===")
        print("Before first access")

        // 첫 접근 - 초기화 발생
        let service1 = lazyService!
        print("After first access - service.name: \(service1.name)")

        // 두 번째 접근 - 같은 인스턴스 반환
        let service2 = lazyService!

        print("Are same instance: \(service1 === service2)")
        print("Service1 initCount: \(service1.initCount)")
        print("Service2 initCount: \(service2.initCount)")
    }

    private func testLazyWithProtocol() {
        print("\n=== Test: Lazy with Protocol ===")
        print("Before protocol access")

        // 첫 접근 - 초기화 발생
        let impl1 = lazyProtocolService!
        print("After protocol access - protocolName: \(impl1.protocolName)")

        // 현재 구현에서는 프로토콜 타입의 경우 weak storage에서
        // 키 매칭 이슈로 인해 인스턴스가 재생성될 수 있습니다.
        let impl2 = lazyProtocolService!

        // 프로토콜 타입이므로 클래스 타입으로 캐스팅해서 비교
        let impl1Class = impl1 as? TestLazyImpl
        let impl2Class = impl2 as? TestLazyImpl
        print("Note: Protocol-based lazy has key mismatch issue in current implementation")
        print("Are same instance: \(impl1Class === impl2Class)")
    }

    private func testLazyMemoryManagement() {
        print("\n=== Test: Lazy Memory Management ===")
        print("Testing weak storage behavior")

        // 첫 번째 인스턴스 가져오기
        let service1 = lazyService!
        print("First instance acquired - initCount: \(service1.initCount)")

        // 같은 인스턴스인지 확인
        let service2 = lazyService!
        print("Second instance acquired - same instance: \(service1 === service2)")

        // weak storage가 실제로 weak를 유지하는지 확인하기 위해
        // Container 내부의 WeakBox를 통해 참조가 유지되는지 테스트
        // (현재 구현에서는 Container가 계속 유지하므로 weak reference는 해제되지 않음)

        print("Note: Container.shared는 전역 싱글톤이므로 weakStorage가 계속 유지됩니다")
        print("weak 참조가 정상 동작하려면 Container가 해제되거나 unregister가 호출되어야 합니다")
    }

    deinit {
        unregisterObjects()
    }
}

// 테스트 실행
let tests = LazyTests()
tests.runAllTests()

print("\n=== All tests completed ===")


