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
    
    static let sharedManager = UserAccessor()
    
    var userListener: ListenerRegistration?
    
    var currentUid = Auth.auth().currentUser?.uid
    var currentUser: User?
    
    func setCurrentUser(completion: @escaping (Bool) -> Void) {
        self.currentUid = Auth.auth().currentUser?.uid
        
        guard let uid = self.currentUid else {
            completion(false)
            return
        }
        
        self.getApecificUser(memberUid: uid) {
            [weak self] (result) in
            guard let self = self else { return }

            switch result {
            case .success(let snapshot):
            
                guard let snapshot = snapshot,
                let dic = snapshot.data() else {
                    return
                }

                var user = User(dic: dic)
                user.uid = snapshot.documentID
                
                self.currentUser = user

                completion(true)
            case .failure(_):
                print("currentUserの取得に失敗しました。")
                completion(false)
                return
            }
        }
    }
    
    func returnCurrentUser() -> User? {
        guard let currentUser = self.currentUser else {
            return nil
        }
        
        return currentUser
    }
    
    
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
            self.userListener = User.targetCollectionRef().addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Users情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
        }
    }
    
    /// users、DocumentID配下にuserを作成する
    func setUserData(memberUid: String, docData: [String: Any], isMerge: Bool = false, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            User.identificationTargetCollectionRef(memberUid).setData(docData, merge: isMerge) {
                (error) in
                if let error = error {
                    print("UserをFirestoreへの保存に失敗しました。\(error)" )
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func checkUniqueUserId(userId: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            User.uniqueTargetCollectionRef(userId: userId).getDocuments {
                (snapshot, error) in
                
                if let error = error {
                    print("user情報の取得に失敗しました。\(error)")
                    completion(false)
                    return
                }

                guard let snapshot = snapshot else {
                    completion(false)
                    return
                }
                
                if snapshot.documents.count <= 0 {
                    completion(true)
                    return
                }
                
                completion(false)
            }
        
        }
    }
    
    func removeUserListener() {
        self.userListener?.remove()
        self.userListener = nil
    }
}
