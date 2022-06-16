//
//  NewsRealmModel.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 16.06.2022.
//

import Foundation
import RealmSwift

final class ArticleRealmModel: Object {
    @objc dynamic var author: String?
    @objc dynamic var imageURL: String?
    @objc dynamic var content: String?
    @objc dynamic var title: String = ""
    @objc dynamic var specification: String?
    @objc dynamic var url: String = ""
    @objc dynamic var publishedAt: String = ""
    @objc dynamic var isFavorite: Bool = false
    
    override static func primaryKey() -> String? {
        return "url"
    }

    convenience init(article: News.Article) {
        self.init()
        self.author = article.author
        self.imageURL = article.imageURL
        self.content = article.content
        self.title = article.title
        self.specification = article.description
        self.url = article.url
        self.publishedAt = article.publishedAt
        self.isFavorite = article.isFavorite
    }
}
