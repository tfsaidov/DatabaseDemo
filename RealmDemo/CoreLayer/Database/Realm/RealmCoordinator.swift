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
    
    func create<T>(_ model: T.Type, keyedValues: [[String: Any]], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            try self.safeWrite(in: realm) {
                guard let model = model as? Object.Type else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                var objects: [Object] = []
                keyedValues.forEach {
                    let object = realm.create(model, value: $0, update: .all)
                    objects.append(object)
                }
                
                guard let result = objects as? [T] else {
                    completion(.failure(.wrongModel))
                    return
                }

                completion(.success(result))
            }
        } catch {
            completion(.failure(.error(desription: "Fail to create object in storage")))
        }
    }
    
    func update<T>(_ model: T.Type, predicate: NSPredicate?, keyedValues: [String: Any], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            switch result {
            case .success(let fetchedObjects):
                do {
                    let realm = try Realm()
                    
                    try self?.safeWrite(in: realm) {
                        guard let modifiedObjects = fetchedObjects as? [Object] else {
                            completion(.failure(.wrongModel))
                            return
                        }
                        
                        realm.add(modifiedObjects, update: .modified)
                        completion(.success(fetchedObjects))
                    }
                } catch {
                    completion(.failure(.error(desription: "Fail to update object in storage")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
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
        self.fetch(model, predicate: nil, completion: completion)
    }
    
    func delete<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        do {
            let realm = try Realm()
            
            guard let model = model as? Object.Type else {
                completion(.failure(.wrongModel))
                return
            }
            
            let deletedObjects: Results<Object>
            if let predicate = predicate {
                deletedObjects = realm.objects(model).filter(predicate)
            } else {
                deletedObjects = realm.objects(model)
            }
                
            try self.safeWrite(in: realm) {
                realm.delete(deletedObjects)
                
                guard let results = Array(deletedObjects) as? [T] else {
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
        self.delete(model, predicate: nil, completion: completion)
    }
}
