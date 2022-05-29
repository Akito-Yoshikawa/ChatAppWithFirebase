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
    private var ralmUsers: Results<User>?
    
    // DBから取得したChatRoom
    private var realmChatRoom: Results<ChatRoom>?

    private var usersListener: ListenerRegistration?
    
    @IBOutlet weak var userListTableView: UITableView!
    
    @IBOutlet weak var startChatButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        
        userListTableView.delegate = self
        userListTableView.dataSource = self
        
        
        userListTableView.register(UINib(nibName: "UserListTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        startChatButton.layer.cornerRadius = 15
        startChatButton.isEnabled = false
        startChatButton.addTarget(self, action: #selector(tappedStartButton), for: .touchUpInside)
                
        navigationController?.changeNavigationBarBackGroundColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadUserList()
    }
    
    func reloadUserList() {
        realmChatRoom = ChatRoomAccessor.shardInstance.getAll()
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
            "createdAt": Date()
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
        
        var sqlConditionsString = [currentUid]
        
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
                                
                if !UserAccessor.shardInstance.set(data: user, updatePolicy: .error) {
                    print("Realmに保存に失敗しました。")
                    return
                }

                // 既にチャットを開始している人は表示しない制御
                // chatRoomsを受け取って、uidを比較する
                if let localRealmChatRoom = self.realmChatRoom {
                    for realmChatRoom in localRealmChatRoom {
                        if realmChatRoom.searchMembersUser(searchID: snapshot.documentID) {
                            sqlConditionsString.append(snapshot.documentID)
                        }
                    }
                }
            })
            
            self.ralmUsers = UserAccessor.shardInstance.getExceptingAll(uids: sqlConditionsString)
            
            self.userListTableView.reloadData()
        }
        
    }
}

extension UserListViewController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ralmUsers?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userListTableView.dequeueReusableCell(withIdentifier: "UserListTableViewCell", for: indexPath) as! UserListTableViewCell

        cell.user = ralmUsers?[indexPath.row]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startChatButton.isEnabled = true

        let user = ralmUsers?[indexPath.row]
        self.selectedUser = user

    }
}

