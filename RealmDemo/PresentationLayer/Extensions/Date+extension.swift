//
//  Date+extension.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 14.07.2022.
//

import Foundation

extension Date {
    
    func toString(withFormat format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
