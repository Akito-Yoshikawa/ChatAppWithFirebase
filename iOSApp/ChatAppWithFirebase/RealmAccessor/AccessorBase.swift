//
//  AccessorBase.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/27.
//

import Foundation
import RealmSwift

class AccessorBase {
    
    let realm: Realm
    
    init() {
        realm = try! Realm()
    }
    
    func set(data: Object, updatePolicy: Realm.UpdatePolicy = .error) -> Bool {
        do {
            try realm.write({
                realm.add(data, update: .all)
            })
            
            return true
        } catch let error {
            print("set Error \(error)")
        }
        
        return false
    }
    
    func delete(data: Object) -> Bool {
        do {
            try realm.write({
                realm.delete(data)
            })
            
            return true
        } catch let error {
            print("delete Error  \(error)")
        }
        
        return false
    }
}
