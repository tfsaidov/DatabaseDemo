//
//  AppDelegate.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.06.2022.
//

import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let migrationService: MigrationServiceProtocol = MigrationService.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.checkRealmMigration()
        self.migrateStorageModels()
        AuthStateObserver.shared.state = .authorized(user: User(id: UUID().uuidString,
                                                                name: String.randomString(length: 20),
                                                                loginTime: Date().toString(),
                                                                salary: 123123.123))
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    private func checkRealmMigration() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // on future migration
                }
        })

        Realm.Configuration.defaultConfiguration = config
    }
    
    private func migrateStorageModels() {
        if !UserDefaults.standard.bool(forKey: "isMigratedStorageModels") {
            MigrationStateObserver.shared.state = .begun
            
            self.migrationService.migrateStorageModels { downloadsState in
                switch downloadsState {
                case .success:
                    UserDefaults.standard.set(true, forKey: "isMigratedStorageModels")
                case .failure:
                    break
                }
                MigrationStateObserver.shared.state = .ended
            }
        }
    }
}
