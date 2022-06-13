//
//  String+extension.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 05.06.2022.
//

import Foundation

extension String {
    
    static let empty = ""
    static let whitespace: Character = " "
    
    var isFirstCharacterWhitespace: Bool {
        return self.first == Self.whitespace
    }

    func toDate(withFormat format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}
