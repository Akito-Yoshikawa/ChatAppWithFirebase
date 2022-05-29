//
//  User.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/08.
//

import Foundation
import Firebase
import RealmSwift

class User: Object {
    
    @objc dynamic var email = ""
    @objc dynamic var username = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var profileImageUrl = ""
    
    @objc dynamic var uid = ""
    
    override static func primaryKey() -> String? {
        return "uid"
    }
    
    convenience init(dic: [String: Any]) {
        self.init()
        self.email = dic["email"] as? String ?? ""
        self.username = dic["username"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Date ?? Date()
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
    }
}

