//
//  UserAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/28.
//

import Foundation
import RealmSwift

class UserAccessor: AccessorBase, AccessorProtcol {
    
    static let shardInstance = UserAccessor()
    
    override init() {
        super.init()
    }
    
    func getByID(id: String) -> User? {
        let models = super.realm.objects(User.self).filter("uid == '\(id)'")
        if models.count > 0 {
            return models[0]
        } else {
            return nil
        }
    }

    func getAll() -> Results<User>? {
        return super.realm.objects(User.self).sorted(byKeyPath: "uid")
    }
    
    ///  指定したUser以外を返す
    /// "NOT uid IN {'kqOMO9mbNQTzFIIwES5fraHxQyF3', '2byXds6B6Phvtak3dKJvGjyzGZ03'}"
    /// - Parameter id: UIDの配列
    /// - Returns: User配列
    func getExceptingAll(uids: [String]) -> Results<User>? {
        var sqlConditionsString = "NOT uid IN {"
        for (index, uid) in uids.enumerated() {
            sqlConditionsString.append(contentsOf: "'\(uid)'")
            
            if uids.count - 1 > index {
                sqlConditionsString.append(contentsOf: ", ")
            } else {
                sqlConditionsString.append(contentsOf: "}")
            }
        }
        
        let models = super.realm.objects(User.self).filter(sqlConditionsString)
        if models.count > 0 {
            return models
        } else {
            return nil
        }
    }
}
