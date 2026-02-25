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

// 테스트용 클래스
class TestLazyService {
    var name: String
    var initCount: Int = 0

    init(name: String = "default") {
        self.name = name
        self.initCount += 1
        print("TestLazyService initialized: \(name)")
    }
}

// 프로토콜 및 구현체
protocol TestLazyProtocol: AnyObject {
    var protocolName: String { get }
}

class TestLazyImpl: TestLazyProtocol {
    var protocolName: String = "TestLazyImpl"
    var initCount: Int = 0

    init() {
        self.initCount += 1
        print("TestLazyImpl initialized")
    }
}

// 테스트 클래스 - 인스턴스 메서드에서만 접근
@Unregister(type: (TestLazyService.self, nil), (TestLazyProtocol.self, nil))
class LazyTester {
    // 기본 lazy 초기화 테스트
    @Lazy
    var lazyService: TestLazyService!

    // 프로토콜 타입 lazy 테스트
    @Lazy(impl: TestLazyImpl.self)
    var lazyProtocolService: TestLazyProtocol!

    func testBasicLazy() {
        print("=== Test: Basic Lazy Initialization ===")

        // 아직 초기화되지 않아야 함
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

    func testLazyWithProtocol() {
        print("\n=== Test: Lazy with Protocol ===")

        print("Before protocol access")

        // 첫 접근 - 초기화 발생
        let impl1 = lazyProtocolService!
        print("After protocol access - protocolName: \(impl1.protocolName)")

        // 현재 구현에서는 프로토콜 타입의 경우 weak storage에서
        // 키 매칭 이슈로 인해 인스턴스가 재생성될 수 있습니다.
        // 이는 추후 개선이 필요한 부분입니다.
        let impl2 = lazyProtocolService!

        // 프로토콜 타입이므로 클래스 타입으로 캐스팅해서 비교
        let impl1Class = impl1 as? TestLazyImpl
        let impl2Class = impl2 as? TestLazyImpl
        print("Note: Protocol-based lazy has key mismatch issue in current implementation")
        print("Are same instance: \(impl1Class === impl2Class)")
    }

    func testLazyMemoryManagement() {
        print("\n=== Test: Lazy Memory Management ===")

        // weak 참조이므로 참조가 사라지면 메모리 해제되어야 함
        print("Creating weak reference to lazy service")

        weak var weakService: TestLazyService?

        autoreleasepool {
            let tempService = lazyService!
            weakService = tempService
            print("Inside autoreleasepool - service exists: \(tempService.name)")
        }

        print("After autoreleasepool - weak reference is nil: \(weakService == nil)")
        // 다시 접근하면 재초기화되어야 함
        let newService = lazyService!
        print("After re-access - service.name: \(newService.name)")
    }

    deinit {
        unregisterObjects()
    }
}

// 테스트 실행
let tester = LazyTester()
tester.testBasicLazy()
tester.testLazyWithProtocol()
tester.testLazyMemoryManagement()

print("\n=== All tests completed ===")


