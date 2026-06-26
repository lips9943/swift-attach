//
//  Serviced.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/16/26.
//
import Foundation
import SwiftAttach
import SwiftUI

// MARK: Two Protocols
protocol FirstService {}
protocol SecondService {}
class TwoProtocols: FirstService, SecondService {}

public protocol Repository {
    var text: String! { get }
}

class RepositoryImpl: Repository {
    var text: String! = "Hello, World!"
}

protocol Service : AnyObject {
    var repo: Repository! { get }
}

@Service
class ServiceImpl: Service {
    var repo: Repository!
}

class Utils {
    
}

class MyService: Service {
    var repo: Repository!
}

class Observed: ObservableObject {
    @Published var count: Int = 0
}

@Service
@MainActor
struct ViewModel {
    @Singleton
    var service: (any Service)!
    
    @NonImplement
    var util: Utils!
    
    @Ignore
    var service2: Service
    
    @Named("MyService")
    var myService: (any Service)!
    
    @Named("TwoProtocols")
    var twoProtocols: (FirstService & SecondService)!
    
    @ObservedObject var observed: Observed
    
    init(service2: Service) {
        self.service2 = service2
        self._observed = .init(initialValue: Container().resolveOptional(Observed.self)!)
    }
}

@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        return RepositoryImpl()
    }
    
    func getService() -> any Service {
        return ServiceImpl()
    }
    
    @NonImplement
    func getUtil() -> Utils {
        return Utils()
    }
    
    @Named("MyService")
    func getMyService() -> any Service {
        return MyService()
    }
    
    @Named("TwoProtocols")
    func getTwoProtocols() -> FirstService & SecondService {
        return TwoProtocols()
    }
}

// AttachActivation
struct AppStart {
    init() {
        DIConfig()
    }
}
