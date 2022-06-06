//
//  UserAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/05.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class UserAccessor: NSObject {
    
    static var userListener: ListenerRegistration?
    
    func getAllUsers(completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            User.targetCollectionRef().getDocuments() {
                (snapshot, error) in
                if let error = error {
                    print("Users情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
        }
    }
    
    func getApecificUser(memberUid: String, completion: @escaping (Result<DocumentSnapshot?, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            User.identificationTargetCollectionRef(memberUid).getDocument {
                (userSnapshot, error) in
                if let error = error {
                    print("特定ユーザー情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(userSnapshot))
            }
        }
    }
    
    
    func getUserAddSnapshotListener(completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            UserAccessor.userListener = User.targetCollectionRef().addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Users情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
        }
    }
    
    
    static func removeUserListener() {
        self.userListener?.remove()
        self.userListener = nil
    }
}
