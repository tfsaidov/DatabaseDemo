//
//  RealmService.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 14.06.2022.
//

import Foundation
import RealmSwift

final class RealmCoordinator {
    
    private let backgroundQueue = DispatchQueue(label: "RealmContext", qos: .background)
    private let mainQueue = DispatchQueue.main
    
    private func safeWrite(in realm: Realm, _ block: (() throws -> Void)) throws {
        realm.isInWriteTransaction
        ? try block()
        : try realm.write(block)
    }
}

extension RealmCoordinator: DatabaseCoordinatable {
    
    func create<T>(_ model: T.Type, keyedValues: [String: Any], completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            try self.safeWrite(in: realm) {
                guard let model = model as? Object.Type,
                      let newObject = realm.create(model, value: keyedValues, update: .all) as? T
                else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                completion(.success(newObject))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to create object in storage")))
        }
    }
    
    func save<T>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            try self.safeWrite(in: realm) {
                guard let savedObject = object as? Object else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                realm.add(savedObject, update: .all)
                completion(.success(object))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to save object in storage")))
        }
    }
    
    func update<T>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            try self.safeWrite(in: realm) {
                guard let modifiedObject = object as? Object else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                realm.add(modifiedObject, update: .modified)
                completion(.success(object))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to update object in storage")))
        }
    }
    
    func fetch<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            if let model = model as? Object.Type {
                var objects = realm.objects(model)
                
                if let predicate = predicate {
                    objects = objects.filter(predicate)
                }
                
                guard let results = Array(objects) as? [T] else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                completion(.success(results))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to fetch objects")))
        }
    }
    
    func fetchAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            if let model = model as? Object.Type {
                let objects = realm.objects(model)
                
                guard let result = Array(objects) as? [T] else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                completion(.success(result))
            }
            
        } catch {
            completion(.failure(.error(desription: "Fail to fetch all objects")))
        }
    }
    
    func delete<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        guard let predicate = predicate else {
            completion(.failure(.unknown))
            return
        }
        
        do {
            let realm = try Realm()
            
            guard let model = model as? Object.Type else {
                completion(.failure(.wrongModel))
                return
            }
            
            let deletedObject = realm.objects(model).filter(predicate)
                
            try self.safeWrite(in: realm) {
                realm.delete(deletedObject)
                
                guard let results = Array(deletedObject) as? [T] else {
                    completion(.success([]))
                    return
                }
                
                completion(.success(results))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to delete object from storage")))
        }
    }
    
    func deleteAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            guard let model = model as? Object.Type else {
                completion(.failure(.wrongModel))
                return
            }
            
            let deletedObject = realm.objects(model)
            
            try self.safeWrite(in: realm) {
                realm.delete(deletedObject)
                
                guard let results = Array(deletedObject) as? [T] else {
                    completion(.success([]))
                    return
                }
                
                completion(.success(results))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to delete objects from storage")))
        }
    }
}
