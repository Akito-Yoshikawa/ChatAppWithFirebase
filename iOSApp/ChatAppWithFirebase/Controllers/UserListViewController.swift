//
//  UserListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/10.
//

import UIKit
import Firebase
import Nuke

class UserListViewController: UIViewController {

    private let cellId = "cellId"
    private var users = [User]()
    private var selectedUser: User?
    
    public var chatRooms = [ChatRoom]()

    @IBOutlet weak var userListTableView: UITableView!
    
    @IBOutlet weak var startChatButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        
        userListTableView.delegate = self
        userListTableView.dataSource = self
        
        startChatButton.layer.cornerRadius = 15
        startChatButton.isEnabled = false
        startChatButton.addTarget(self, action: #selector(tappedStartButton), for: .touchUpInside)
                
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .rgb(red: 39, green: 49, blue: 69)
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        
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
            
            
            self.dismiss(animated: true, completion: nil)
            print("ChatRoom情報の保存に成功しました。")
        }

        
        
    }
    
    
    private func fetchUserInfoFromFireStore() {
        Firestore.firestore().collection("users").getDocuments { (snapshot,err)  in
            if let err = err {
                print("user情報の取得に失敗しました。\(err)")
                return
            }
            
            snapshot?.documents.forEach({ (snapshot) in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                
                user.uid = snapshot.documentID
                
                guard let uid = Auth.auth().currentUser?.uid else {
                    return
                }

                // 同じユーザーだった場合
                if uid == snapshot.documentID {
                    return
                }
                
                self.users.append(user)

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
        let cell = userListTableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! UserListTableViewCell

        cell.user = users[indexPath.row]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startChatButton.isEnabled = true

        let user = users[indexPath.row]
        self.selectedUser = user

    }
}

class UserListTableViewCell: UITableViewCell {
    
    var user: User? {
        didSet {
            userNameLabel.text = user?.username

            userImageView.loadImage(with: user?.profileImageUrl ?? "")
        }
    }
    
    
    @IBOutlet weak var userNameLabel: UILabel!    
    @IBOutlet weak var userImageView: UIImageView!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 32.5
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
