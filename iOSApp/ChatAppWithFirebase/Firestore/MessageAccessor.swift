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
    
    func getMessage(chatRoomId: String, latestMessageId: String, completion: @escaping (Result<DocumentSnapshot?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            Message.targetCollectionRef(chatRoomId, latestMessageId).getDocument {
                (messageSnapshot, error)  in
                if let error = error {
                    print("メッセージ情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                }
                                
                completion(.success(messageSnapshot))
            }
        }
    }
}
