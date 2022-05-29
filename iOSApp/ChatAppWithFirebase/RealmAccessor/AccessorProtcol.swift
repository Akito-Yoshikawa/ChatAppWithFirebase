//
//  AccessorProtcol.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/27.
//

import Foundation
import RealmSwift
import AVFoundation

protocol AccessorProtcol {
    associatedtype ObjectType: Object
    func getByID(id: String) -> ObjectType?
    func getAll() -> Results<ObjectType>?
    func set(data: Object, updatePolicy: Realm.UpdatePolicy) -> Bool
    func delete(data: Object) -> Bool
}
