//
//  GenericObservable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation

final class GenericObservable<T> {
    
    private var observers = Set<WeakObserver<T>>()
//    private var observers = Array<WeakObserver<T>>()
    
    func subscribe(_ object: AnyObject, handler: @escaping (T) -> Void) {
        let newObserver = WeakObserver<T>(observer: object, handler: handler)
        
        guard !self.observers.contains(newObserver) else { return }
        
        self.observers.insert(newObserver)
    }
    
    func unsubscribe(_ object: AnyObject) {
        if let indexToRemove = self.observers.firstIndex(where: { $0.observer === object }) {
            self.observers.remove(at: indexToRemove)
        }
    }
    
    func notify(with object: T) {
        var objects = [AnyObject]()
        var handlers = [(T) -> ()]()
        
        objects = self.observers.compactMap { $0.observer }
        self.observers = self.observers.filter { $0.observer != nil }
        handlers = self.observers.compactMap { $0.handler }
        
        withExtendedLifetime(objects) {
            handlers.forEach { $0(object) }
        }
    }
}
