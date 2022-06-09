//
//  MessageAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/05.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class MessageAccessor: NSObject {
    
    static let sharedManager = MessageAccessor()
    
    func getMessage(chatRoomId: String, latestMessageId: String, completion: @escaping (Result<DocumentSnapshot?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            Message.targetCollectionRef(chatRoomId, latestMessageId).getDocument {
                (messageSnapshot, error)  in
                if let error = error {
                    print("メッセージ情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                                
                completion(.success(messageSnapshot))
            }
        }
    }
        
    func getAllMessageSnapshotListener(chatRoomId: String, completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            Message.allMessagesTargetCollectionRef(chatRoomId).addSnapshotListener() {
                (messageSnapshot, error)  in
                if let error = error {
                    print("全てのメッセージ情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(messageSnapshot?.documentChanges))
            }
        }
    }
    
    func setMessage(chatRoomId: String, messageId: String, docData: [String: Any], completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            Message.targetCollectionRef(chatRoomId, messageId).setData(docData) {
                (error) in
                if let error = error {
                    print("メッセージ情報の保存に失敗しました。\(error)")
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
}
