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

protocol Service {
    var repo: Repository! { get }
}

@Service
class ServiceImpl: Service {
    var repo: Repository!
}

class Utils {
    
}

@Service
class ViewModel {
    @Singleton
    var service: Service!
    @NonImplement
    @Singleton
    var util: Utils!
    @Ignore
    var service2: Service
    
    init(service2: Service) {
        self.service2 = service2
    }
}

@AttachConfig
class DIConfig {
    func getRepository() -> Repository {
        return RepositoryImpl()
    }
    
    func getService() -> Service {
        return ServiceImpl()
    }
    
    func getUtil() -> Utils {
        return Utils()
    }
}

// AttachActivation
struct AppStart {
    init() {
        DIConfig()
    }
}
