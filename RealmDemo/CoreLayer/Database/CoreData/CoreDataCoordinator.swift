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


    // MARK: Static

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


    // MARK: Private Static

    private static func setup(coordinator: CoreDataCoordinator) -> Result<CoreDataCoordinator, DatabaseError> {
        let storeCoordinator = coordinator.persistentStoreCoordinator

        let fileManager = FileManager.default
        let storeName = "\(coordinator.modelName).sqlite"

        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let persistentStoreURL = documentsDirectoryURL?.appendingPathComponent(storeName)

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
        self.mainContext.perform { [weak self] in
            var entities: [Any] = Array(repeating: true, count: keyedValues.count)

            keyedValues.enumerated().forEach { (index, keyedValues) in
                guard
                    let mainContext = self?.mainContext,
                    let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: model.self),
                                                                       in: mainContext)
                else {
                    completion(.failure(.wrongModel))
                    return
                }

                let entity = NSManagedObject(entity: entityDescription,
                                             insertInto: mainContext)
                entity.setValuesForKeys(keyedValues)
                entities[index] = entity
            }
            
            if let objects = entities as? [T] {
                completion(.success(objects))
            } else {
                completion(.failure(.wrongModel))
            }
        }
    }
    
    func update<T>(_ model: T.Type, predicate: NSPredicate?, keyedValues: [String: Any], completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject] else {
                    return
                }

                self?.mainContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        fetchedObject.setValuesForKeys(keyedValues)
                    }

                    let castFetchedObjects = fetchedObjects as? [T] ?? []
                    completion(.success(castFetchedObjects))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func delete<T>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: predicate) { [weak self] result in
            switch result {
            case .success(let fetchedObjects):
                guard let fetchedObjects = fetchedObjects as? [NSManagedObject] else {
                    completion(.failure(.wrongModel))
                    return
                }

                self?.mainContext.perform {
                    fetchedObjects.forEach { fetchedObject in
                        self?.mainContext.delete(fetchedObject)
                    }
                    let deletedObjects = fetchedObjects as? [T] ?? []
                    completion(.success(deletedObjects))
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

        self.mainContext.perform { [weak self] in
            let request = model.fetchRequest()
            request.predicate = predicate
            guard
                let fetchRequestResult = try? self?.mainContext.fetch(request),
                let fetchedObjects = fetchRequestResult as? [T]
            else {
                completion(.failure(.wrongModel))
                return
            }

            completion(.success(fetchedObjects))
        }
    }
    
    func fetchAll<T>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void) where T : Storable {
        self.fetch(model, predicate: nil, completion: completion)
    }
    
    func saveContext(with completion: ((Result<Void, DatabaseError>) -> Void)?) {
        self.mainContext.perform { [weak self] in
            do {
                if self?.mainContext.hasChanges == true {
                    try self?.mainContext.save()
                    completion?(.success(()))
                }
            } catch let error {
                completion?(.failure(.error(desription: "Unable to save changes of main context.\nError - \(error.localizedDescription)")))
            }
        }
    }
}
