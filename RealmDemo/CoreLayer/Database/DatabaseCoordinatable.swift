//
//  DatabaseCoordinatable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 16.06.2022.
//

import Foundation

enum DatabaseError: Error {
    /// Не найдена модель объекта.
    case wrongModel
    /// Кастомная ошибка.
    case error(desription: String)
    /// Неизвестная ошибка.
    case unknown
}

protocol DatabaseCoordinatable {
    /// Создание объекта заданного типа.
    func create<T: Storable>(_ model: T.Type, keyedValues: [String: Any], completion: @escaping (Result<T, DatabaseError>) -> Void)
    /// Сохранение объекта.
    func save<T: Storable>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void)
    /// Обновление объекта заданного типа с помощью предиката.
    func update<T: Storable>(object: T, completion: @escaping (Result<T, DatabaseError>) -> Void)
    /// Удаление объектов заданного типа с помощью предиката.
    func delete<T: Storable>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void)
    /// Удаление всех объектов заданного типа.
    func deleteAll<T: Storable>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void)
    /// Получение объектов заданного типа с помощью предиката.
    func fetch<T: Storable>(_ model: T.Type, predicate: NSPredicate?, completion: @escaping (Result<[T], DatabaseError>) -> Void)
    /// Получение объектов заданного типа.
    func fetchAll<T: Storable>(_ model: T.Type, completion: @escaping (Result<[T], DatabaseError>) -> Void)
}
