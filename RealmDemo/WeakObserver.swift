//
//  WeakObserver.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation

final class WeakObserver<T>: Hashable {
    
    weak var observer: AnyObject?
    private(set) var handler: ((T) -> Void)?
    
    init(observer: AnyObject?, handler: ((T) -> Void)?) {
        self.observer = observer
        self.handler = handler
    }
    
    init(observer: AnyObject?) {
        self.observer = observer
    }
    
    func hash(into hasher: inout Hasher) {
        guard let observer = observer else {
            return hasher.combine(0)
        }
        
        hasher.combine(ObjectIdentifier(observer).hashValue)
    }
    
    static func == (lhs: WeakObserver<T>, rhs: WeakObserver<T>) -> Bool {
        return lhs.observer === rhs.observer
    }
}
