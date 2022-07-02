//
//  MigrationState.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation

enum MigrationState {
    case notBegun
    case begun
    case ended
}

final class MigrationStateObserver {
    
    static let shared = MigrationStateObserver()
    
    private init() {}
    
    var state: MigrationState = .notBegun {
        didSet {
            guard self.state != oldValue else {
                return
            }
            
            self.observable.notify(with: self.state)
        }
    }
    
    private let observable = GenericObservable<MigrationState>()
    
    func subscribe(_ object: AnyObject, handler: @escaping (MigrationState) -> Void) {
        self.observable.subscribe(object, handler: handler)
    }
    
    func unsubscribe(_ object: AnyObject) {
        self.observable.unsubscribe(object)
    }
}
