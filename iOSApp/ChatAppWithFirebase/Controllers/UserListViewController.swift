//
//  UserListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/10.
//

import UIKit
import Firebase
import Nuke
import RealmSwift
import PKHUD

class UserListViewController: UIViewController {

    private let cellId = "UserListTableViewCell"
    private var selectedUser: User?
//    private var ralmUsers: Results<User>?
    private var users = [User]()

    // DBから取得したChatRoom
    public var chatRooms = [ChatRoom]()
//    private var realmChatRoom: Results<ChatRoom>?

    private var usersListener: ListenerRegistration?
    
    @IBOutlet weak var userListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        
        userListTableView.delegate = self
        userListTableView.dataSource = self
        
        
        userListTableView.register(UINib(nibName: "UserListTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)

        navigationController?.changeNavigationBarBackGroundColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadUserList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usersListener?.remove()
    }
    
    func reloadUserList() {
        
//        self.realmChatRoom = Array(ChatRoomAccessor.shardInstance.getAll()!)
//        print(self.realmChatRoom)

//        self.realmChatRoom = nil

        fetchUserInfoFromFireStore()
    }
    
    @objc private func tappedStartButton() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let partherUid = self.selectedUser?.uid else {
            return
        }
        
        let members = [uid, partherUid]
        
        let docData = [
            "members": members,
            "latestMessageId": "",
            "createdAt": Timestamp()
        ] as [String: Any]
        
        Firestore.firestore().collection("chatRooms").addDocument(data: docData) { (err) in
            if let err = err {
                print("ChatRoom情報の取得に失敗しました。\(err)")
                return
            }
            
            self.reloadUserList()
            
            self.selectedUser = nil
            print("ChatRoom情報の保存に成功しました。")
        }
    }
    
    
    private func fetchUserInfoFromFireStore() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
                
        usersListener = Firestore.firestore().collection("users").addSnapshotListener { (snapshot, err)  in
            
            if let err = err {
                print("user情報の取得に失敗しました。\(err)")
                return
            }
            
            snapshot?.documents.forEach({ (snapshot) in
                let dic = snapshot.data()
                let user = User(dic: dic)
                
                user.uid = snapshot.documentID
                
                guard let uid = Auth.auth().currentUser?.uid else {
                    return
                }

                // 同じユーザーだった場合
                if uid == snapshot.documentID {
                    return
                }

                // 既にチャットを開始している人は表示しない制御
                // chatRoomsを受け取って、uidを比較する

                for chatRoom in self.chatRooms {
                    if chatRoom.searchMembersUser(searchID: snapshot.documentID) {
                        if self.users.count != 0 {
                            self.users.removeLast()
                        }
                    }
                }
            })
            
            
            self.userListTableView.reloadData()
        }
        
    }
}

extension UserListViewController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userListTableView.dequeueReusableCell(withIdentifier: "UserListTableViewCell", for: indexPath) as! UserListTableViewCell

        cell.user = users[indexPath.row]

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]

        let storyboard = UIStoryboard.init(name: "UserDetail", bundle: nil)
        let userDetailViewController = storyboard.instantiateViewController(withIdentifier: "UserDetailViewController") as! UserDetailViewController
        userDetailViewController.partherUser = user
        userDetailViewController.delegate = self
        
        self.present(userDetailViewController, animated: true, completion: nil)
    }
}

extension UserListViewController: ChatStartDelegate {
    
    func chatStart() {
        
        reloadUserList()
    }
}
