//
//  ChatRoomViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/04/26.
//

import UIKit
import Firebase

class ChatRoomViewController: UIViewController {
    
    public var user: User?
    public var chatRoom: ChatRoom?
    
    private let cellId = "ChatRoomTableViewcellId"
    
    private var messages = [Message]()
    
    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
        view.delegate = self
       return view
    }()
    
    @IBOutlet weak var chatRoomTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatRoomTableView.backgroundColor = .green
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self
        chatRoomTableView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        chatRoomTableView.backgroundColor = .rgb(red: 118, green: 140, blue: 180)
        
        fetchMassages()
    }
    
    
    override var inputAccessoryView: UIView? {
        get {
            return chatInputAccessoryView
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    private func fetchMassages() {
        guard let chatRoomDocId = chatRoom?.documentId else {
            return
        }

        Firestore.firestore().collection("chatRooms").document(chatRoomDocId).collection("messages").addSnapshotListener { (snapshots, err) in
            if let err = err {
                print("メッセージ情報の取得に失敗しました。\(err)")
                return
            }
            
            snapshots?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type {
                case .added:
                    let dic = documentChange.document.data()
                    
                    let message = Message(dic: dic)
                    self.messages.append(message)

                    self.chatRoomTableView.reloadData()
                    
                    print("message dic: ", dic)
                    
                case .modified, .removed: break
                    
                    
                }
            })
            
        }
    }
}

extension ChatRoomViewController: ChatInputAccessoryViewDelegate {
    func tappedSendButton(text: String) {
        guard let chatRoomDocId = chatRoom?.documentId else {
            return
        }

        guard let name = user?.username else {
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        chatInputAccessoryView.removeText()
        
        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message": text
        ] as [String: Any]


        Firestore.firestore().collection("chatRooms").document(chatRoomDocId).collection("messages").document().setData(docData) { (err) in
            if let err = err {
                print("メッセージ情報の保存に失敗しました。\(err)")
                return
            }
            
            print("メッセージ情報の保存に成功しました。")
            
            
        }
    }
}


extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        chatRoomTableView.estimatedRowHeight = 20
                
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
        cell.message = messages[indexPath.row]
        
//        cell.messageText = messages[indexPath.row]
        return cell
    }
}
