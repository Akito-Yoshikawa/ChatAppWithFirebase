//
//  UserListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/10.
//

import UIKit
import Firebase
import Nuke
import PKHUD

class UserListViewController: UIViewController {

    private let cellId = "UserListTableViewCell"
    private var selectedUser: User?
    private var users = [User]()

    private var userAccessor = UserAccessor()
    
    private var chatRoomAccessor = ChatRoomAccessor()
    
    private var usersListener: ListenerRegistration?
    
    @IBOutlet weak var userListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        
        userListTableView.delegate = self
        userListTableView.dataSource = self
        
        
        userListTableView.register(UINib(nibName: "UserListTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)

        navigationController?.changeNavigationBarBackGroundColor()
        
        reloadUserList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    private func fetchUserInfoFromFireStore() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        users = []
                
        userAccessor.getUserAddSnapshotListener() { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let documentChanges):
                
                documentChanges?.forEach({ (documentChange) in
                    let dic = documentChange.document.data()
                    var user = User(dic: dic)
                    
                    user.uid = documentChange.document.documentID
                    
                    // 同じユーザーだった場合
                    if uid == documentChange.document.documentID {
                        return
                    }
                    
                    self.users.append(user)
                })
            
                // 既にチャットを開始している人は表示しない制御
                // chatRoomsを受け取って、uidを比較する
                self.chatRoomAccessor.getChatRoomsAddSnapshotListener() { [weak self] (result) in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let chatRoomdDcumentChanges):
                        chatRoomdDcumentChanges?.forEach({ (chatRoomdDcumentDocumentChange) in
                            let dic = chatRoomdDcumentDocumentChange.document.data()
                            let chatRoom = ChatRoom.init(dic: dic)
                            
                            if chatRoom.searchMembersUser(searchID: uid) {
                                
                                for (index, user) in self.users.enumerated() {

                                    if user.searchMembersUser(members: chatRoom.members) {
                                        self.users.remove(at: index)
                                    }
                                }
                                
                            }
                        })
                        
                        self.userListTableView.reloadData()
                    case .failure(_): break
                    }
                }
            case .failure(_):
                self.showSingleBtnAlert(title: "ユーザー情報の取得に失敗しました。")
            }
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
        
        self.present(userDetailViewController, animated: true, completion: nil)
    }
}
