//
//  Changable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 12.06.2022.
//

import Foundation

protocol Changable: AnyObject {
    func change(with viewModel: ViewModelProtocol)
}
