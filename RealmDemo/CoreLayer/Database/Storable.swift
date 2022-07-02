//
//  Storable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 16.06.2022.
//

import Foundation
import RealmSwift
import CoreData

protocol Storable {}

extension Object: Storable {}
extension NSManagedObject: Storable {}
