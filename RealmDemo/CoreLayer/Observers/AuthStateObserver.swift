//
//  AuthStateObserver.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.07.2022.
//

import Foundation

enum AuthState: Equatable {
    case notAuthorized
    case authorized(user: User)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized):
            return true
        case (.authorized(let lhsUser), .authorized(let rhsUser)):
            return lhsUser.id == rhsUser.id
        default:
            return false
        }
    }
}

final class AuthStateObserver {
    
    static let shared = AuthStateObserver()
    
    private init() {}
    
    var state: AuthState = .notAuthorized {
        didSet {
            guard self.state != oldValue else {
                return
            }
            
            self.observable.notify(with: self.state)
        }
    }
    
    private let observable = GenericObservable<AuthState>()
    
    func subscribe(_ object: AnyObject, handler: @escaping (AuthState) -> Void) {
        self.observable.subscribe(object, handler: handler)
    }
    
    func unsubscribe(_ object: AnyObject) {
        self.observable.unsubscribe(object)
    }
}
