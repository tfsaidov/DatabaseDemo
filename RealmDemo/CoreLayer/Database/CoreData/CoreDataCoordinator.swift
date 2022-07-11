//
//  CoreDataCoordinator.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation
import CoreData

final class CoreDataCoordinator {
    
    let modelName: String

    private let model: NSManagedObjectModel
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

    private lazy var saveContext: NSManagedObjectContext = {
        let masterContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        masterContext.parent = self.mainContext
        masterContext.mergePolicy = NSOverwriteMergePolicy
        return masterContext
    }()
    
    private lazy var mainContext: NSManagedObjectContext = {
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = self.masterContext
        mainContext.mergePolicy = NSOverwriteMergePolicy
        return mainContext
    }()
    
    private lazy var masterContext: NSManagedObjectContext = {
        let masterContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        masterContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        masterContext.mergePolicy = NSOverwriteMergePolicy
        return masterContext
    }()
    
    private let mainQueue = DispatchQueue.main

    private init(url: URL) throws {
        let pathExtension = url.pathExtension
        
        guard let name = try? url.lastPathComponent.replace(pathExtension, replacement: "") else {
            throw DatabaseError.error(desription: "")
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            throw DatabaseError.error(desription: "")
        }

        self.modelName = name
        self.model = model
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    }

    private convenience init(name: String, bundle: Bundle? = nil) throws {
        let fileExtension = "momd"

        if
           let bundle = bundle,
           let url = bundle.url(forResource: name, withExtension: fileExtension) {
            try self.init(url: url)
        } else if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            try self.init(url: url)
        } else {
            throw DatabaseError.find(model: name, bundle: bundle)
        }
    }

    static func create(url modelUrl: URL) -> Result<CoreDataCoordinator, DatabaseError> {
        do {
            let coordinator = try CoreDataCoordinator(url: modelUrl)
            return Self.setup(coordinator: coordinator)
        } catch let error as DatabaseError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error: error))
        }
    }

    private static func setup(coordinator: CoreDataCoordinator) -> Result<CoreDataCoordinator, DatabaseError> {
        let storeCoordinator = coordinator.persistentStoreCoordinator

        let fileManager = FileManager.default
        let storeName = "\(coordinator.modelName)" + "sqlite"

        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let persistentStoreURL = documentsDirectoryURL?.appendingPathComponent(storeName)
//        print("⭐️ \(persistentStoreURL)")

        var databaseError: DatabaseError?
        do {
            let options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]

            try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                    configurationName: nil,
                                                    at: persistentStoreURL,
                                                    options: options)
        } catch {
            databaseError = .store(model: coordinator.modelName)
        }

        if let error = databaseError {
            return .failure(error)
        }
        
        return .success(coordinator)
    }
    
    private func save(with context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        guard context.hasChanges else {
            completion?()
            return
        }
        
        context.perform {
            do {
                try context.save()
            } catch let error {
                print("Unable to save changes of context.\nError - \(error.localizedDescription)")
            }
            
            if let parentContext = context.parent {
                self.save(with: parentContext, completion: completion)
            } else {
                completion?()
            }
        }
    }
}

extension CoreDataCoordinator: DatabaseCoordinatable {
    
    func create<T>(_ model: T.Type, keyedValues: [[String : Any]], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.saveContext.perform { [weak self] in
            guard let self = self else { return }
            
            var entities: [Any] = Array(repeating: true, count: keyedValues.count)
            
            keyedValues.enumerated().forEach { (index, keyedValues) in
                guard let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: model.self),
                                                                         in: self.saveContext)
                else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                let entity = NSManagedObject(entity: entityDescription,
                                             insertInto: self.saveContext)
                entity.setValuesForKeys(keyedValues)
                entities[index] = entity
            }
            
            guard let objects = entities as? [T] else {
                completion(.failure(.wrongModel))
                return
            }
            
            guard self.saveContext.hasChanges else {
                completion(.failure(.store(model: String(describing: model.self))))
                return
            }
            
            self.save(with: self.saveContext) {
                completion(.success(objects))
            }
        }
    }
    
    func update<T>(_ model: T.Type, predicate: NSPredicate?, keyedValues: [String: Any], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject] else {
                    return
                }

                self.mainContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        fetchedObject.setValuesForKeys(keyedValues)
                    }
                    
                    let castFetchedObjects = fetchedObjects as? [T] ?? []
                    
                    guard self.mainContext.hasChanges else {
                        completion(.failure(.store(model: String(describing: model.self))))
                        return
                    }
                    
                    do {
                        try self.mainContext.save()
                        completion(.success(castFetchedObjects))
                    } catch let error {
                        completion(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func delete<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject] else {
                    completion(.failure(.wrongModel))
                    return
                }

                self.mainContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        self.mainContext.delete(fetchedObject)
                    }
                    let deletedObjects = fetchedObjects as? [T] ?? []
                    
                    guard self.mainContext.hasChanges else {
                        completion(.failure(.store(model: String(describing: model.self))))
                        return
                    }
                    
                    do {
                        try self.mainContext.save()
                        completion(.success(deletedObjects))
                    } catch let error {
                        completion(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.delete(model, predicate: nil, completion: completion)
    }
    
    func fetch<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        guard let model = model as? NSManagedObject.Type else {
            completion(.failure(.wrongModel))
            return
        }
        
        self.saveContext.perform {
            print("💧 \(Thread.current)")
            let request = model.fetchRequest()
            request.predicate = predicate
            guard
                let fetchRequestResult = try? self.saveContext.fetch(request),
                let fetchedObjects = fetchRequestResult as? [T]
            else {
                self.mainQueue.async { completion(.failure(.wrongModel)) }
                return
            }
            
            print("💧 💧 \(Thread.current)")
            self.mainQueue.async { completion(.success(fetchedObjects)) }
        }
    }
    
    func fetchAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: nil, completion: completion)
    }
}
