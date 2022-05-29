//
//  ChatRoomAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/28.
//

import Foundation
import RealmSwift

class ChatRoomAccessor: AccessorBase, AccessorProtcol {
    
    static let shardInstance = ChatRoomAccessor()
    
    override init() {
        super.init()
    }

    func getByID(id: String) -> ChatRoom? {
        let models = super.realm.objects(ChatRoom.self).filter("documentId == '\(id)'")
        if models.count > 0 {
            return models[0]
        } else {
            return nil
        }
    }
    
    func getAll() -> Results<ChatRoom>? {
        return super.realm.objects(ChatRoom.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    /// 全object削除
    /// - Returns: 成功したかどうか true:成功 false:失敗
    func deleteAll() -> Bool {
        do {
            try realm.write({
                self.realm.deleteAll()
            })
            return true
        } catch let error {
            print("set Error \(error)")
        }
        
        return false
    }
                            
}
