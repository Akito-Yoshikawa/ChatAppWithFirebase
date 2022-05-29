//
//  ChatRoom.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/11.
//

import Foundation
import Firebase
import RealmSwift

class Member: Object {
    @objc dynamic var path = ""
}

class ChatRoom: Object {
    
    @objc dynamic var latestMessageId = ""
    var members = List<Member>()
    @objc dynamic var createdAt: Date?
    
    @objc dynamic var latestMessage: Message?
    @objc dynamic var partnerUser: User?
    
    @objc dynamic var documentId = ""

    override static func primaryKey() -> String? {
        return "documentId"
    }
    
    convenience init(dic: [String: Any]) {
        self.init()
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        let members = dic["members"] as? [String] ?? [String]()

        for path in members {
            let member = Member()
            member.path = path
            self.members.append(member)
        }
        let timestamp = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.createdAt = timestamp.dateValue()
    }
}


extension ChatRoom {
    
    ///  Array型のStringをList型のStringに変換
    /// - Returns: Array型のString
    func transformToJSON() -> Array<String> {
        var results = [String]()
        for obj in self.members {
            results.append(obj.path)
        }
        return results
    }
        
    ///  最後にメッセージした時間→ルームを作成した時間の順でDateを返す
    /// - Returns: (最後にメッセージした時間→ルームを作成した時間)
    public func chatListdateReturn() -> Date {
        guard let createdAtLatestMessage = self.latestMessage?.createdAt else {
            return self.createdAt ?? Date()
        }

        return createdAtLatestMessage
    }
    
    ///  membersから受け取ったIDが存在するかチェックする
    /// - Parameter searchID: 検索するID
    /// - Returns: true: 存在する false:存在しない
    public func searchMembersUser(searchID: String) -> Bool {
        for member in self.members {
            if member.path == searchID {
                return true
            }
        }
        
        return false
    }
    
}
