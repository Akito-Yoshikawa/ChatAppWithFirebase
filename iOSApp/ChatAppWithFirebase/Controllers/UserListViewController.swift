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
    private var showAllUsers = [User]()
    
    @IBOutlet weak var userSearchBar: UISearchBar!
        
    @IBOutlet weak var userListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        
        userListTableView.delegate = self
        userListTableView.dataSource = self
        
        userSearchBar.delegate = self
        
        userListTableView.register(UINib(nibName: "UserListTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        
        
        userListTableView.keyboardDismissMode = .onDrag

        navigationController?.changeNavigationBarBackGroundColor()
        
        navigationItem.title = "チャット開始"
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
        self.userListTableView.reloadData()
        
        fetchUserInfoFromFireStore()
    }
    
    private func fetchUserInfoFromFireStore() {
        
        guard let currentUid = UserAccessor.sharedManager.currentUid else {
            return
        }
        
        // ユーザー情報取得
        UserAccessor.sharedManager.getUserAddSnapshotListener() { [weak self] (result) in
            guard let self = self else { return }
            
            self.showAllUsers = []
            
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
                    
                    self.showAllUsers.append(user)
                })
            
                // ユーザーを最新順にソートする
                self.showAllUsers.sort { (m1, m2) -> Bool in
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
                            
                            for (index, user) in self.showAllUsers.enumerated() {
                                if user.searchMembersUser(members: chatRoom.members) {
                                    self.showAllUsers.remove(at: index)
                                }
                            }
                        })
                        
                        // 検索バーの検索項目にテキストが入力されているか
                        guard let searchText = self.userSearchBar.text, !searchText.isEmpty else {
                            self.users = self.showAllUsers
                            self.userListTableView.reloadData()
                            return
                        }
                        // 入力されていたら、追加したユーザーでも絞り込む
                        self.userSearch(searchText)
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

extension UserListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        userSearch(searchText)
    }

    private func userSearch(_ text: String) {
        
        self.users = self.showAllUsers

        if !text.isEmpty {
            var newArray = [User]()
            self.users.forEach ({ user in
                if user.username.contains(text) ||  user.userID.contains(text) {
                    newArray.append(user)
                }
            })
            self.users = newArray
        }
        userListTableView.reloadData()
    }
}
