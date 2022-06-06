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
    
    enum ListenerNames: String {
        case chatListViewController = "chatListViewController"
        case userListViewController = "userListViewController"
    }
    
    static var chatRoomListenerUseChatList: ListenerRegistration?
    static var chatRoomListenerUseUserList: ListenerRegistration?

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
    
    func getChatRoomsAddSnapshotListener(listenerName: ListenerNames, completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let chatListListener = ChatRoom.targetCollectionRef().addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("ChatRooms情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
            
            switch listenerName {
            case .chatListViewController:
                ChatRoomAccessor.chatRoomListenerUseChatList = chatListListener
            case .userListViewController:
                ChatRoomAccessor.chatRoomListenerUseUserList = chatListListener
            }
        }
    }
    
    static func removeAllChatRoomListener() {
        self.chatRoomListenerUseChatList?.remove()
        self.chatRoomListenerUseUserList?.remove()
        
        self.chatRoomListenerUseChatList = nil
        self.chatRoomListenerUseUserList = nil
    }
}

