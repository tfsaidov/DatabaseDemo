//
//  RealmConcurrency.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 17.06.2022.
//

import UIKit
import RealmSwift

final class RealmConcurrencyViewController: UIViewController {
    
    private let backgroundQueue = DispatchQueue(label: "RealmConcurrencyQueue", qos: .background)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 1. If you create an instance of a Realm, you can use it only on the same thread. If you want to use the same Realm on another thread, you have to create a new Realm instance on that other thread otherwise application will crash.
        /// Bad.
        let realmOnMainThread = try! Realm()
        
        self.backgroundQueue.async {
            let newArticle = ArticleRealmModel()
            newArticle.isFavorite = true
            
            try! realmOnMainThread.write { // this queue is running on a different thread, so you can't use `realmOnMainThread` here!
                realmOnMainThread.add(newArticle)
            }
        }
        /// OK.
        self.backgroundQueue.async {
            let realmOnBackgroundThread = try! Realm()
            
            let newArticle = ArticleRealmModel()
            newArticle.isFavorite.toggle()
            
            try! realmOnBackgroundThread.write {
                realmOnBackgroundThread.add(newArticle)
            }
        }
        
        /// 2. If you get a Realm object, list, results, or any other Realm type from a Realm, you can use it only on the same thread. If you want to use the same object, or whatever on another thread, you have re-fetch the object or pass through ThreadSafeReference otherwise application will crash.
        /// Bad.
        let articles = realmOnMainThread.objects(ArticleRealmModel.self)
        // Do more things with `realmOnMainThread`...
        
        self.backgroundQueue.async {
            let articles = realmOnMainThread.objects(ArticleRealmModel.self) // this queue is running on a different thread, so you can't use `realmOnMainThread` here!
        }
        /// OK.
        let oneMoreArticles = realmOnMainThread.objects(ArticleRealmModel.self)
        // Do more things with `realmOnMainThread`...
        
        self.backgroundQueue.async {
            // You can pass Realm configurations between threads, that's okay.
            let realmOnBackgroundThread = try! Realm()
            let articles = realmOnBackgroundThread.objects(ArticleRealmModel.self) // okay, since we opened `realmOnBackgroundThread` on the same thread.
        }
        
        /// Bad.
        let andOneMoreArticles = realmOnMainThread.objects(ArticleRealmModel.self)
        guard let article = andOneMoreArticles.first else { return }
        self.backgroundQueue.async {
            article.isFavorite.toggle()
            
            try! realmOnMainThread.write {
                realmOnMainThread.add(article, update: .modified)
            }
        }
        /// OK.
        let anotherArticles = realmOnMainThread.objects(ArticleRealmModel.self)
        guard let anotherArticle = anotherArticles.first else { return }
        let anotherArticleRef = ThreadSafeReference(to: anotherArticle)
        self.backgroundQueue.async {
            let realmOnBackgroundThread = try! Realm()
            
            guard let modifiedArticle = realmOnBackgroundThread.resolve(anotherArticleRef) else { return }
            
            modifiedArticle.isFavorite.toggle()
            
            try! realmOnBackgroundThread.write {
                realmOnBackgroundThread.add(modifiedArticle, update: .modified)
            }
        }
    }
}
