//
//  ChatRoomAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/05.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class ChatRoomAccessor: NSObject {
    
    var chatRoomListener: ListenerRegistration?
    
    func getChatRooms(completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            ChatRoom.targetCollectionRef().getDocuments {
                (snapshot, error) in
                if let error = error {
                    print("ChatRooms情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                                
                completion(.success(snapshot?.documentChanges))
            }
        }
    }
    
    func getChatRoomsAddSnapshotListener(completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.chatRoomListener = ChatRoom.targetCollectionRef().addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("ChatRooms情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
        }
    }
}

