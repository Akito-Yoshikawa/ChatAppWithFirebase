//
//  UINavigationController-Extension.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/05/25.
//

import UIKit

extension UINavigationController {
    
    func changeNavigationBarBackGroundColor() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .rgb(red: 39, green: 49, blue: 69)
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
            self.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}

