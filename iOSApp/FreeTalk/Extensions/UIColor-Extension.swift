//
//  UIColor-Extension.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/04/26.
//

import Foundation
import UIKit

extension UIColor {
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

