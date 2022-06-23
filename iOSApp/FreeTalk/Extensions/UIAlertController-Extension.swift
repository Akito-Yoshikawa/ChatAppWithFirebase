//
//  UIAlertController-Extension.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/24.
//

import UIKit

extension UIAlertController {
    
    class func singleBtnAlert(title: String,
                              message: String,
                              actionTitle: String = "OK",
                              handler: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action) in
            handler?()
        }))
        return alert
    }
    
    class func cancelableAlert(title: String,
                               message: String,
                               okActionTitle: String = "OK",
                               okHandler: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: okActionTitle, style: .default, handler: { (action) in
            okHandler?()
        }))
        return alert
    }
    
    class func commonlableAlert(title: String,
                                message: String,
                                okActionTitle: String = "OK",
                                okHandler: (() -> Void)? = nil,
                                cancelActionTitle: String = "Cancel",
                                cancelHandler: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okActionTitle, style: .default, handler: { (action) in
            okHandler?()
        }))
        alert.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: { (action) in
            cancelHandler?()
        }))
        return alert
    }
}
