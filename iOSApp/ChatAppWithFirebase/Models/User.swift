//
//  User.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/08.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct User {
    
    let email: String
    let username: String
    let createdAt: Timestamp
    let profileImageUrl: String
    let selfIntroduction: String?
    let userID: String
    
    var uid: String?
    
    init(dic: [String: Any]) {
        self.email = dic["email"] as? String ?? ""
        self.username = dic["username"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
        self.selfIntroduction = dic["selfIntroduction"] as? String ?? ""
        self.userID = dic["userID"] as? String ?? ""
    }
    
    static func targetCollectionRef() -> CollectionReference {
        return Firestore.firestore().collection("users")
    }
    
    static func identificationTargetCollectionRef(_ memberUid: String) -> DocumentReference {
        return Firestore.firestore().collection("users").document(memberUid)
    }
}

extension User {
    
    ///  membersから受け取ったIDが存在するかチェックする
    /// - Parameter searchID: 検索するID
    /// - Returns: true: 存在する false:存在しない
    public func searchMembersUser(members: [String]) -> Bool {
        for membersId in members {
            if self.uid == membersId {
                return true
            }
        }
        
        return false
    }
}
