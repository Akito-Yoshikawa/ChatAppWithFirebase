//
//  ChatRoom.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/11.
//

import Foundation
import Firebase

class ChatRoom {
    
    let latestMessageId: String
    let members: [String]
    let createdAt: Timestamp
    
    var latestMessage: Message?
    var documentId: String?
    var partnerUser: User?
    
    init(dic: [String: Any]) {
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        self.members = dic["members"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
    
    ///  最後にメッセージした時間→ルームを作成した時間の順でDateを返す
    /// - Returns: (最後にメッセージした時間→ルームを作成した時間)
    public func chatListdateReturn() -> Date {
        guard let createdAtLatestMessage = self.latestMessage?.createdAt.dateValue() else {
            return self.createdAt.dateValue()
        }
        
        return createdAtLatestMessage
    }
    
    ///  membersから受け取ったIDが存在するかチェックする
    /// - Parameter searchID: 検索するID
    /// - Returns: true: 存在する false:存在しない
    public func searchMembersUser(searchID: String) -> Bool {
        for membersId in self.members {
            if searchID == membersId {
                return true
            }
        }
        
        return false
    }
    
}
