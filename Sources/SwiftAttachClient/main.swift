//
//  Serviced.swift
//  SwiftAttach
//
//  Created by 고혁준 on 5/16/26.
//
import Foundation
import SwiftAttach

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

@Service
class ViewModel {
    @Singleton
    var service: (any Service)!
    
    @NonImplement
    var util: Utils!
    
    @Ignore
    var service2: Service
    
    @Named("MyService")
    var myService: (any Service)!
    
    init(service2: Service) {
        self.service2 = service2
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
}

// AttachActivation
struct AppStart {
    init() {
        DIConfig()
    }
}
