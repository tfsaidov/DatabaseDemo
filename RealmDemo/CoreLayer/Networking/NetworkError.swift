//
//  NetworkError.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.06.2022.
//

import Foundation

enum NetworkError: Error {
    case `default`
    case serverError
    case parseError(reason: String)
    case unknownError
}
