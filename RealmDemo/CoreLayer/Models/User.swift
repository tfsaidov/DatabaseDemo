//
//  User.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.07.2022.
//

import Foundation

struct User {
    let id: String
    let name: String
    let loginTime: String
    let salary: Decimal
    
    var keyedValues: [String: Any] {
        return [
            "id": self.id,
            "name": self.name,
            "loginTime": self.loginTime,
            "salary": self.salary
        ]
    }

}
