//
//  Message.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/12.
//

import Foundation
import Firebase
import RealmSwift

class Message: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var message = ""
    @objc dynamic var uid = ""
    @objc dynamic var createdAt = Date()
    
    @objc dynamic var partnerUser: User?
    
    convenience init(dic: [String: Any]) {
        self.init()
        self.name = dic["name"] as? String ?? ""
        self.message = dic["message"] as? String ?? ""
        self.uid = dic["uid"] as? String ?? ""
        
        let timestamp = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.createdAt = timestamp.dateValue()
    }
}
