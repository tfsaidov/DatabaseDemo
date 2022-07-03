//
//  MigrationService.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import Foundation

enum MigrationError: Error {
    case error(description: String)
}

protocol MigrationServiceProtocol: AnyObject {
    var realmCoordinator: DatabaseCoordinatable { get }
    var coreDataCoordinator: DatabaseCoordinatable { get }
    
    /// Миграция объектов из Realm в CoreData.
    func migrateStorageModels(completion: @escaping (Result<Void, MigrationError>) -> Void)
}

final class MigrationService {
    
    static let shared: MigrationServiceProtocol = MigrationService()
    
    let realmCoordinator: DatabaseCoordinatable
    let coreDataCoordinator: DatabaseCoordinatable
    
    private init() {
        self.realmCoordinator = Self.createDatabaseCoordinator(for: .realm)
        self.coreDataCoordinator = Self.createDatabaseCoordinator(for: .coreData)
    }
    
    private static func createDatabaseCoordinator(for type: DatabaseType) -> DatabaseCoordinatable {
        switch type {
        case .realm:
            return RealmCoordinator()
        case .coreData:
            let bundle = Bundle.main
            guard let url = bundle.url(forResource: "DatabaseDemo", withExtension: "momd") else {
                fatalError("Can't find DatabaseDemo.xcdatamodelId in main Bundle")
            }
            
            switch CoreDataCoordinator.create(url: url) {
            case .success(let database):
                return database
            case .failure:
                switch CoreDataCoordinator.create(url: url) {
                case .success(let database):
                    return database
                case .failure(let error):
                    fatalError("Unable to create CoreData Database. Error - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func keyedValues(from articles: [News.Article]) -> [[String: Any]] {
        var keyedValues: [[String: Any]] = []
        
        articles.forEach {
            let keyedValue = $0.keyedValues
            keyedValues.append(keyedValue)
        }
        
        return keyedValues
    }
}

extension MigrationService: MigrationServiceProtocol {
    
    func migrateStorageModels(completion: @escaping (Result<Void, MigrationError>) -> Void) {
        self.realmCoordinator.fetchAll(ArticleRealmModel.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let articleObjects):
                guard !articleObjects.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                let articles = articleObjects.map { News.Article(articleRealmModel: $0) }
                let keyedValues = self.keyedValues(from: articles)
                self.coreDataCoordinator.create(ArticleCoreDataModel.self, keyedValues: keyedValues) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(.error(description: error.localizedDescription)))
                    }
                }
            case .failure(let error):
                completion(.failure(.error(description: error.localizedDescription)))
            }
        }
    }
}

