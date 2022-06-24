//
//  ChatRoomAccessor.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/06/05.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class ChatRoomAccessor: NSObject {
    
    static let sharedManager = ChatRoomAccessor()
        
    enum ListenerNames: String {
        case chatListViewController = "chatListViewController"
        case userListViewController = "userListViewController"
    }
    
    var chatRoomListenerUseChatList: ListenerRegistration?
    var chatRoomListenerUseUserList: ListenerRegistration?

    func getChatRooms(curentUid: String, completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            ChatRoom.targetCollectionRef(currentUid: curentUid).getDocuments {
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
    
    func getChatRoomsAddSnapshotListener(listenerName: ListenerNames, cureentUid: String, completion: @escaping (Result<[DocumentChange]?, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let chatListListener = ChatRoom.targetCollectionRef(currentUid: cureentUid).addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("ChatRooms情報の取得に失敗しました。\(error)")
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documentChanges))
            }
            
            switch listenerName {
            case .chatListViewController:
                self.chatRoomListenerUseChatList = chatListListener
            case .userListViewController:
                self.chatRoomListenerUseUserList = chatListListener
            }
        }
    }
    
    func setChatRoom(docData: [String: Any], completion: @escaping (Error?) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            ChatRoom.targetCollectionRef().addDocument(data: docData) {
                (error) in
                if let error = error {
                    print("ChatRoom情報の保存に失敗しました。\(error)")
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
    
    /// ChatRoom直下のlatestMessageにメッセージIDをセットする
    func setLatestMessage(chatRoomId: String, latestMessageData: [String: Any], completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            ChatRoom.identificationTargetCollectionRef(chatRoomDocId: chatRoomId).updateData(latestMessageData) {
                (error) in
                if let error = error {
                    print("最新メッセージの保存に失敗しました。\(error)")
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func removeAllChatRoomListener() {
        self.chatRoomListenerUseChatList?.remove()
        self.chatRoomListenerUseUserList?.remove()
        
        self.chatRoomListenerUseChatList = nil
        self.chatRoomListenerUseUserList = nil
    }
}

