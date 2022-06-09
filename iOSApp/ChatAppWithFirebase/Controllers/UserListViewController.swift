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
    private var users = [User]()
    
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
     
        /// リスナーがnilの場合に取得を行う(ログアウト時削除)
        if UserAccessor.sharedManager.userListener == nil {
            reloadUserList()
        }
    }
        
    func reloadUserList() {
        users = []
        
        fetchUserInfoFromFireStore()
    }
    
    private func fetchUserInfoFromFireStore() {
        
        guard let currentUid = UserAccessor.sharedManager.currentUid else {
            return
        }
        
        // ユーザー情報取得
        UserAccessor.sharedManager.getUserAddSnapshotListener() { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let documentChanges):
                
                documentChanges?.forEach({ (documentChange) in
                    let dic = documentChange.document.data()
                    var user = User(dic: dic)
                    
                    user.uid = documentChange.document.documentID
                    
                    // 同じユーザーだった場合
                    if currentUid == documentChange.document.documentID {
                        return
                    }
                    
                    self.users.append(user)
                })
            
                // ユーザーを最新順にソートする
                self.users.sort { (m1, m2) -> Bool in
                    let m1Date = m1.createdAt.dateValue()
                    let m2Date = m2.createdAt.dateValue()
                    return m1Date > m2Date
                }
                
                // チャットルーム情報取得、既に会話を始めている人を制御する
                ChatRoomAccessor.sharedManager.getChatRoomsAddSnapshotListener(listenerName: .userListViewController, cureentUid: currentUid) { [weak self] (result) in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let chatRoomdDcumentChanges):
                        chatRoomdDcumentChanges?.forEach({ (chatRoomdDocumentChange) in
                            let dic = chatRoomdDocumentChange.document.data()
                            let chatRoom = ChatRoom.init(dic: dic)
                            
                            for (index, user) in self.users.enumerated() {
                                if user.searchMembersUser(members: chatRoom.members) {
                                    self.users.remove(at: index)
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
        
        userListTableView.deselectRow(at: indexPath, animated: true)
    }
}
