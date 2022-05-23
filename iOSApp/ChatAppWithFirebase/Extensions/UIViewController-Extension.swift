//
//  UIViewController-Extension.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/24.
//

import UIKit

extension UIViewController {

    func showSingleBtnAlert(title: String = "",
                            message: String = "",
                            actionTitle: String = "OK",
                            handler: (() -> Void)? = nil) {
        let alert = UIAlertController.singleBtnAlert(title: title, message: message, actionTitle: actionTitle, handler: handler)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCancelableAlert(title: String = "",
                             message: String = "",
                             okActionTitle: String = "OK",
                             okHandler: (() -> Void)? = nil) {
        let alert = UIAlertController.cancelableAlert(title: title, message: message, okActionTitle: okActionTitle, okHandler: okHandler)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCommonlableAlert(title: String = "",
                              message: String = "",
                              okActionTitle: String = "OK",
                              okHandler: (() -> Void)? = nil,
                              cancelActionTitle: String = "Cancel",
                              cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController.commonlableAlert(title: title, message: message, okActionTitle: okActionTitle, okHandler: okHandler, cancelActionTitle: cancelActionTitle, cancelHandler: cancelHandler)
        self.present(alert, animated: true, completion: nil)
    }
}
