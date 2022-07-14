//
//  CoreDataCoordinator.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation
import CoreData

final class CoreDataCoordinator {
    
    private enum CompletionHandlerType {
        case success
        case failure(error: DatabaseError)
    }
    
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
    
    private func save(with context: NSManagedObjectContext,
                      completionHandler: (() -> Void)? = nil,
                      failureCompletion: ((DatabaseError) -> Void)? = nil) {
        /*
         if context === self.saveContext {
             self.handler(for: .failure(error: .error(desription: "Something went wrong")),
                          using: context,
                          contextWorksInOwnQueue: false,
                          with: completionHandler,
                          and: failureCompletion)
         }
         */
        
        // Нет обработки ошибки контекста, связанного с NSPersistentStoreCoordinator.
        guard context.hasChanges else {
            if context.parent != nil {
                self.handler(for: .failure(error: .error(desription: "Context has not changes")),
                             using: context,
                             contextWorksInOwnQueue: false,
                             with: completionHandler,
                             and: failureCompletion)
            }
            return
        }
        
        context.perform {
            do {
                try context.save()
            } catch let error {
                if context.parent != nil {
                    self.handler(for: .failure(error: .error(desription: "Unable to save changes of context.\nError - \(error.localizedDescription)")),
                                 using: context,
                                 with: completionHandler,
                                 and: failureCompletion)
                }
            }
            
            guard let parentContext = context.parent else { return }
            
            self.handler(for: .success, using: context, with: completionHandler, and: failureCompletion)
            self.save(with: parentContext, completionHandler: completionHandler, failureCompletion: failureCompletion)
        }
    }
    
    private func handler(for type: CompletionHandlerType,
                         using context: NSManagedObjectContext,
                         contextWorksInOwnQueue: Bool = true,
                         with completionHandler: (() -> Void)?,
                         and failureCompletion: ((DatabaseError) -> Void)?) {
        switch type {
        case .success:
            if context.concurrencyType == .mainQueueConcurrencyType {
                if contextWorksInOwnQueue {
                    completionHandler?()
                } else {
                    self.mainContext.perform {
                        completionHandler?()
                    }
                }
            }
        case .failure(let error):
            if context.concurrencyType == .privateQueueConcurrencyType {
                if context.parent != nil {
                    self.mainContext.perform {
                        failureCompletion?(error)
                    }
                }
            } else {
                if contextWorksInOwnQueue {
                    failureCompletion?(error)
                } else {
                    self.mainContext.perform {
                        failureCompletion?(error)
                    }
                }
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
                    self.mainContext.perform {
                        completion(.failure(.wrongModel))
                    }
                    return
                }
                
                let entity = NSManagedObject(entity: entityDescription,
                                             insertInto: self.saveContext)
                entity.setValuesForKeys(keyedValues)
                entities[index] = entity
            }
            
            guard let objects = entities as? [T] else {
                self.mainContext.perform {
                    completion(.failure(.wrongModel))
                }
                return
            }
            
            self.save(with: self.saveContext,
                      completionHandler: {
                completion(.success(objects))
            },
                      failureCompletion: { error in
                completion(.failure(error))
            })
        }
    }
    
    func update<T>(_ model: T.Type, predicate: NSPredicate?, keyedValues: [String: Any], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject], !fetchedObjects.isEmpty else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                self.saveContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        fetchedObject.setValuesForKeys(keyedValues)
                    }
                    
                    let castFetchedObjects = fetchedObjects as? [T] ?? []
                    
                    self.save(with: self.saveContext,
                              completionHandler: {
                        completion(.success(castFetchedObjects))
                    },
                              failureCompletion: { error in
                        completion(.failure(error))
                    })
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
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject], !fetchedObjects.isEmpty else {
                    completion(.failure(.wrongModel))
                    return
                }

                self.saveContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        self.saveContext.delete(fetchedObject)
                    }
                    
                    let deletedObjects = fetchedObjects as? [T] ?? []
                    
                    self.save(with: self.saveContext,
                              completionHandler: {
                        completion(.success(deletedObjects))
                    },
                              failureCompletion: { error in
                        completion(.failure(error))
                    })
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
            let request = model.fetchRequest()
            request.predicate = predicate
            
            guard
                let fetchRequestResult = try? self.saveContext.fetch(request),
                let fetchedObjects = fetchRequestResult as? [T]
            else {
                self.mainContext.perform {
                    completion(.failure(.wrongModel))
                }
                return
            }
            
            self.mainContext.perform {
                completion(.success(fetchedObjects))
            }
        }
    }
    
    func fetchAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: nil, completion: completion)
    }
}
