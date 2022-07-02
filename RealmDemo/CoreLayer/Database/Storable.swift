//
//  Storable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 16.06.2022.
//

import Foundation
import RealmSwift

protocol Storable: ThreadConfined {}

extension Object: Storable {}
