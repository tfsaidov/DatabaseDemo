//
//  Setupable.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 05.06.2022.
//

import Foundation

protocol ViewModelProtocol {}

protocol Setupable {
    func setup(with viewModel: ViewModelProtocol)
}
