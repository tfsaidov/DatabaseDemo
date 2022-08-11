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
    
    private lazy var backgroundContext: NSManagedObjectContext = {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.mergePolicy = NSOverwriteMergePolicy
        backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return backgroundContext
    }()

    private lazy var mainContext: NSManagedObjectContext = {
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return mainContext
    }()

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
}

extension CoreDataCoordinator: DatabaseCoordinatable {
    
    func create<T>(_ model: T.Type, keyedValues: [[String : Any]], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            var entities: [Any] = Array(repeating: true, count: keyedValues.count)
            
            keyedValues.enumerated().forEach { (index, keyedValues) in
                guard let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: model.self),
                                                                         in: self.backgroundContext)
                else {
                    completion(.failure(.wrongModel))
                    return
                }
                
                let entity = NSManagedObject(entity: entityDescription,
                                             insertInto: self.backgroundContext)
                entity.setValuesForKeys(keyedValues)
                entities[index] = entity
            }
            
            guard let objects = entities as? [T] else {
                completion(.failure(.wrongModel))
                return
            }
            
            guard self.backgroundContext.hasChanges else {
                completion(.failure(.store(model: String(describing: model.self))))
                return
            }
            
            do {
                try self.backgroundContext.save()
                
                self.mainContext.perform {
                    completion(.success(objects))
                }
            } catch let error {
                completion(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
            }
        }
    }
    
    func update<T>(_ model: T.Type, predicate: NSPredicate?, keyedValues: [String: Any], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject] else {
                    completion(.failure(.wrongModel))
                    return
                }

                self.backgroundContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        fetchedObject.setValuesForKeys(keyedValues)
                    }
                    
                    let castFetchedObjects = fetchedObjects as? [T] ?? []
                    
                    guard self.backgroundContext.hasChanges else {
                        completion(.failure(.store(model: String(describing: model.self))))
                        return
                    }
                    
                    do {
                        try self.backgroundContext.save()
                        
                        self.mainContext.perform {
                            completion(.success(castFetchedObjects))
                        }
                    } catch let error {
                        self.mainContext.perform {
                        completion(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
                        }
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

                self.backgroundContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        self.backgroundContext.delete(fetchedObject)
                    }
                    let deletedObjects = fetchedObjects as? [T] ?? []
                    
                    guard self.backgroundContext.hasChanges else {
                        completion(.failure(.store(model: String(describing: model.self))))
                        return
                    }
                    
                    do {
                        try self.backgroundContext.save()
                        
                        self.mainContext.perform {
                            completion(.success(deletedObjects))
                        }
                    } catch let error {
                        self.mainContext.perform {
                            completion(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
                        }
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
        
        self.backgroundContext.perform {
            let request = model.fetchRequest()
            request.predicate = predicate
            guard
                let fetchRequestResult = try? self.backgroundContext.fetch(request),
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
    
    /// Функционал двух несвязанных друг с другом контекстов. Оба контекста связаны с NSPersinstentStore.
    /// - Parameters:
    ///   - backgroundContext: Контекст, использующий фоновую очередью.
    ///   - mainContext: Контекст, использующий главную очередью.
//    func foo(backgroundContext: NSManagedObjectContext, mainContext: NSManagedObjectContext) {
//        backgroundContext.perform {
//            let user = UserCoreDataModel(context: backgroundContext)
//            user.name = "Timur"
//
//            mainContext.perform {
//                let usersObjectId = user.objectID
//                let object = mainContext.object(with: usersObjectId)
//
//                if let newUser = object as? UserCoreDataModel {
//                    newUser.name = "Timur Saidov"
//                }
//
//                do {
//                    try self.mainContext.save()
//                } catch {
//                    print("Save context error")
//                }
//
//                let request = UserCoreDataModel.fetchRequest()
//                request.sortDescriptors = [
//                    NSSortDescriptor(key: "salary", ascending: true)
//                ]
//                let users = try? mainContext.fetch(request)
//
//                backgroundContext.perform {
//                    let request = UserCoreDataModel.fetchRequest()
//                    request.fetchLimit = 20
//                    request.fetchOffset = 0
//                    let users = try? self.saveContext.fetch(request)
//                }
//            }
//        }
//    }
}
