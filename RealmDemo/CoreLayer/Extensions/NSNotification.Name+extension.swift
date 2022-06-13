//
//  NSNotification.Name+extension.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 11.06.2022.
//

import Foundation

extension NSNotification.Name {
    static let wasLikedArticle = NSNotification.Name("wasLikedArticle")
    static let didRemoveArticleFromFavorites = NSNotification.Name("didRemoveArticleFromFavorites")
}
