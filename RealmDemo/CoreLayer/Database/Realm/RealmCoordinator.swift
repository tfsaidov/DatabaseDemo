//
//  RealmService.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 14.06.2022.
//

import Foundation
import RealmSwift

final class RealmCoordinator {
    
    private let backgroundQueue = DispatchQueue(label: "RealmContextQueue", qos: .background)
    private let mainQueue = DispatchQueue.main
    
    private func safeWrite(in realm: Realm, _ block: (() throws -> Void)) throws {
        realm.isInWriteTransaction
        ? try block()
        : try realm.write(block)
    }
}

extension RealmCoordinator: DatabaseCoordinatable {
    
    func create<T>(_ model: T.Type, keyedValues: [String: Any], completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                try self.safeWrite(in: realm) {
                    guard let model = model as? Object.Type,
                          let newObject = realm.create(model, value: keyedValues, update: .all) as? T
                    else {
                        self.mainQueue.async { completion(.failure(.wrongModel)) }
                        return
                    }
                    
                    let objectRef = ThreadSafeReference(to: newObject)
                    
                    self.mainQueue.async {
                        do {
                            let realmOnMainThread = try Realm()
                            realmOnMainThread.refresh()
                            
                            guard let newObject = realmOnMainThread.resolve(objectRef) else {
                                completion(.failure(.wrongModel))
                                return
                            }
                            
                            completion(.success(newObject))
                        } catch {
                            completion(.failure(.error(desription: "Fail to fetch all objects")))
                        }
                    }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to create object in storage"))) }
            }
        }
    }
    
    func save<T>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                try self.safeWrite(in: realm) {
                    guard let savedObject = object as? Object else {
                        self.mainQueue.async { completion(.failure(.wrongModel)) }
                        return
                    }
                    
                    realm.add(savedObject, update: .all)
                    self.mainQueue.async { completion(.success(object)) }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to save object in storage"))) }
            }
        }
    }
    
    func update<T>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                try self.safeWrite(in: realm) {
                    guard let modifiedObject = object as? Object else {
                        self.mainQueue.async { completion(.failure(.wrongModel)) }
                        return
                    }
                    
                    realm.add(modifiedObject, update: .modified)
                    self.mainQueue.async { completion(.success(object)) }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to update object in storage"))) }
            }
        }
    }
    
    func fetch<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                guard let model = model as? Object.Type else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                var objects = realm.objects(model)
                
                if let predicate = predicate {
                    objects = objects.filter(predicate)
                }
                
                guard let results = Array(objects) as? [T] else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                self.mainQueue.async { completion(.success(results)) }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to fetch objects"))) }
            }
        }
    }
    
    func fetchAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                guard let model = model as? Object.Type else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                let objects = realm.objects(model)
                
                guard let result = Array(objects) as? [T] else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                let objectsRef = result.map { ThreadSafeReference(to: $0) }
                
                self.mainQueue.async {
                    do {
                        let realmOnMainThread = try Realm()
                        realmOnMainThread.refresh()
                        let result = objectsRef.compactMap { realmOnMainThread.resolve($0) }
                        completion(.success(result))
                    } catch {
                        completion(.failure(.error(desription: "Fail to fetch all objects")))
                    }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to fetch all objects"))) }
            }
        }
    }
    
    func delete<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        guard let predicate = predicate else {
            completion(.failure(.unknown))
            return
        }
        
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                guard let model = model as? Object.Type else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                let deletedObject = realm.objects(model).filter(predicate)
                
                try self.safeWrite(in: realm) {
                    realm.delete(deletedObject)
                    
                    guard let results = Array(deletedObject) as? [T] else {
                        self.mainQueue.async { completion(.success([])) }
                        return
                    }
                    
                    self.mainQueue.async { completion(.success(results)) }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to delete object from storage"))) }
            }
        }
    }
    
    func deleteAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.backgroundQueue.async {
            do {
                let realm = try Realm()
                
                guard let model = model as? Object.Type else {
                    self.mainQueue.async { completion(.failure(.wrongModel)) }
                    return
                }
                
                let deletedObject = realm.objects(model)
                
                try self.safeWrite(in: realm) {
                    realm.delete(deletedObject)
                    
                    guard let results = Array(deletedObject) as? [T] else {
                        self.mainQueue.async { completion(.success([])) }
                        return
                    }
                    
                    self.mainQueue.async { completion(.success(results)) }
                }
            } catch {
                self.mainQueue.async { completion(.failure(.error(desription: "Fail to delete objects from storage"))) }
            }
        }
    }
}
