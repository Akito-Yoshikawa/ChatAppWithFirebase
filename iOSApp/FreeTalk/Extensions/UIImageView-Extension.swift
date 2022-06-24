//
//  UIImageView-Extension.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/05/10.
//

import Foundation
import UIKit
import Nuke

extension UIImageView {
    
    func loadImage(with urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        loadImage(url: url)
    }

    func loadImage(url: URL) {
        Nuke.loadImage(with: url, into: self)
    }
}
