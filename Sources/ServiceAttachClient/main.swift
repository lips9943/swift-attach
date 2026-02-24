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


