//
//  SceneDelegate.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.06.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    enum DataType {
        case request
        case mock
    }

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        self.window = UIWindow(windowScene: windowScene)
        let databaseCoordinator = MigrationService.shared.coreDataCoordinator //.realmCoordinator //.coreDataCoordinator
        let rootViewController = UITabBarController()
        rootViewController.viewControllers = [
            UINavigationController(rootViewController: NewsViewController(dataType: .mock,
                                                                          databaseCoordinator: databaseCoordinator)),
            UINavigationController(rootViewController: FavoritesViewController(databaseCoordinator: databaseCoordinator))
        ]
        rootViewController.viewControllers?.enumerated().forEach({
            if $0 == 0 {
                $1.tabBarItem = UITabBarItem(title: "Main",
                                             image: UIImage(systemName: "house"),
                                             selectedImage: UIImage(systemName: "house.fill"))
            } else if $0 == 1 {
                $1.tabBarItem = UITabBarItem(title: "Favorites",
                                             image: UIImage(systemName: "star"),
                                             selectedImage: UIImage(systemName: "star.fill"))
            }
        })
        self.window?.rootViewController = rootViewController
        self.window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
