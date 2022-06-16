//
//  News.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.06.2022.
//

import Foundation

struct News: Decodable {
    let status: String
    let articles: [Article]

    struct Article: Decodable, Equatable {
        
        static let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "MMMM d, yyyy"
            df.locale = Locale(identifier: "en_EN")
            return df
        }()
        
        let author: String?
        let imageURL: String?
        let content: String?
        let title: String
        let description: String?
        let url: String
        let publishedAt: String
        var isFavorite: Bool
        
        var publishedAtString: String? {
            guard let publishedAtDate = self.publishedAt.toDate() else { return nil }
            
            return Self.dateFormatter.string(from: publishedAtDate)
        }
        
        var keyedValues: [String: Any] {
            return [
                "author": self.author ?? "",
                "imageURL": self.imageURL ?? "",
                "content": self.content ?? "",
                "title": self.title,
                "specification": self.description ?? "",
                "url": self.url,
                "publishedAt": self.publishedAt,
                "isFavorite": self.isFavorite
            ]
        }

        struct Source: Decodable {
            let id: String?
            let name: String
        }

        enum CodingKeys: String, CodingKey {
            case author, title, description, url, publishedAt, content
            case imageURL = "urlToImage"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.author = try container.decodeIfPresent(String.self, forKey: .author)
            self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
            self.content = try container.decodeIfPresent(String.self, forKey: .content)
            self.title = try container.decode(String.self, forKey: .title)
            self.description = try container.decodeIfPresent(String.self, forKey: .description)
            self.url = try container.decode(String.self, forKey: .url)
            self.publishedAt = try container.decode(String.self, forKey: .publishedAt)
            self.isFavorite = false
        }
        
        init(articleRealmModel: ArticleRealmModel) {
            self.author = articleRealmModel.author
            self.imageURL = articleRealmModel.imageURL
            self.content = articleRealmModel.content
            self.title = articleRealmModel.title
            self.description = articleRealmModel.specification
            self.url = articleRealmModel.url
            self.publishedAt = articleRealmModel.publishedAt
            self.isFavorite = articleRealmModel.isFavorite
        }
        
        static func ==(lhs: Article, rhs: Article) -> Bool {
            return lhs.url == rhs.url
        }
    }
}
