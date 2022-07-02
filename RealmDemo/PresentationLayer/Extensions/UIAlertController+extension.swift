//
//  UIAlertController.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 02.07.2022.
//

import UIKit

extension UIAlertController {
    
    static func create(preferredStyle: UIAlertController.Style,
                       title: String, message: String? = nil,
                       hasAction: Bool = false, actionInfo: (title: String?, style: UIAlertAction.Style)? = nil,
                       hasCancel: Bool = false,
                       actionCompletionHandler: ((UIAlertAction) -> Void)? = nil,
                       cancelCompletionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        if hasAction {
            let action = UIAlertAction(title: actionInfo?.title ?? .empty, style: actionInfo?.style ?? .default) { action in
                actionCompletionHandler?(action)
            }
            alertController.addAction(action)
        }
        if hasCancel {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                cancelCompletionHandler?(action)
            }
            alertController.addAction(cancelAction)
        }
        
        return alertController
    }
}
