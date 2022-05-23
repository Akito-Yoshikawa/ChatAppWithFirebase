//
//  ChatListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/04/25.
//

import UIKit
import Firebase
import Nuke

class ChatListViewController: UIViewController {
        
    private let cellId = "cellId"
    private var chatRooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?
    
    private var user: User? {
        didSet {
            navigationItem.title = user?.username
        }
    }
        
    @IBOutlet weak var chatListTableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
         
        setupViews()
        confirmLoggedInUser()

        fetchChatroomsInfoFromFirestore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchLoginUserInfo()
    }
    
    public func fetchChatroomsInfoFromFirestore() {
        chatRoomListener?.remove()
        chatRooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms").addSnapshotListener({ (snapshots, err) in
            if let err = err {
                print("ChatRooms情報の取得に失敗しました。\(err)")
                
                return
            }
            
            snapshots?.documentChanges.forEach({ (documentChange) in
                self.handleAddedDocumentChange(documentChange: documentChange)
            })
            
        })
        
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        
        let dic = documentChange.document.data()
        let chatRoom = ChatRoom.init(dic: dic)
        chatRoom.documentId = documentChange.document.documentID
                
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        let isConatin = chatRoom.members.contains(uid)
        
        if !isConatin {
            return
        }

        chatRoom.members.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                    if let err = err {
                        print("ユーザーの情報に取得に失敗しました。\(err)")
                        return
                    }
                    
                    guard let dic = userSnapshot?.data(),
                          let userDocumentID = userSnapshot?.documentID else {
                        return
                    }
                    
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    chatRoom.partnerUser = user
                    
                    guard let chatroomId = chatRoom.documentId else {
                        return
                    }
                    let latestMessageId = chatRoom.latestMessageId
                    
                    if latestMessageId.isEmpty {
                        self.chatRooms.append(chatRoom)
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err)  in
                        if let err = err {
                            print("最新情報の取得に失敗しました。\(err)")
                            return
                        }
                        
                        guard let dic = messageSnapshot?.data() else {
                            return
                        }
                        let message = Message(dic: dic)
                        chatRoom.latestMessage = message
                        
                        switch documentChange.type {
                        case .modified:
                            // チャットルームが変更されたら、変更された前のチャットルームを削除する
                            for (index, chatRoom) in self.chatRooms.enumerated() {
                                if chatRoom.searchMembersUser(searchID: userDocumentID) {
                                    self.chatRooms.remove(at: index)
                                }
                            }
                        default: break
                        }
                        
                        self.chatRooms.append(chatRoom)
                        
                        // 最新順に上から並び替える
                        self.chatRooms.sort { (m1, m2) -> Bool in
                            let m1Date = m1.chatListdateReturn()
                            let m2Date = m2.chatListdateReturn()
                            return m1Date > m2Date
                        }
                        
                        self.chatListTableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil {
            pushLoginViewController()
        }
    }
    
    private func pushLoginViewController() {
        let storyboar = UIStoryboard(name: "SignUp", bundle: nil)
        let signUpViewController = storyboar.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion:
        nil)
    }
    
    private func setupViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self

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
        
        navigationItem.title = "トーク"

        let rigthBarButton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogoutButton))
        
        navigationItem.rightBarButtonItem = rigthBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    @objc private func tappedLogoutButton() {

        do {
            try Auth.auth().signOut()

            chatRoomListener?.remove()
            chatRooms.removeAll()
            chatListTableView.reloadData()

            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。\(error)")
        }
        
    }
    
    @objc private func tappedNavRightBarButton() {
        let storyboard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewController = storyboard.instantiateViewController(withIdentifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewController)
        let userListVC = nav.viewControllers[0] as! UserListViewController
        userListVC.chatRooms = self.chatRooms

        self.present(nav, animated: true, completion: nil)
    }
    
    private func fetchLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in

            if let err = err {
                print("ユーザーの情報に取得に失敗しました。\(err)")
                return
            }
 
            guard let snapshot = snapshot,
            let dic = snapshot.data() else {
                return
            }

            let user = User(dic: dic)
            
            self.user = user
        }
    }
    
}


// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatRooms[indexPath.row]
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        
        chatRoomViewController.user = user
        chatRoomViewController.chatRoom = chatRooms[indexPath.row]
        
        navigationController?.pushViewController(chatRoomViewController, animated: true)
        
        chatListTableView.deselectRow(at: indexPath, animated: true)
    }
}

class ChatListTableViewCell: UITableViewCell {

    var chatroom: ChatRoom? {
        didSet {
            if let chatroom = chatroom {
                pertnerLabel.text = chatroom.partnerUser?.username
                userImageView.loadImage(with: chatroom.partnerUser?.profileImageUrl ?? "")
                
                dateLabel.text = dateFormatterForDateLabel(date: chatroom.chatListdateReturn())
                latestMessageLabel.text = chatroom.latestMessage?.message
            }
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pertnerLabel: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
    
        userImageView.layer.cornerRadius = 30
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
        
    private func dateFormatterForDateLabel(date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
                
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier:  "Asia/Tokyo")

        // 現在時刻から一週間前
        let nowDate = Date()
        let modifiedDate = Calendar.current.date(byAdding: .day, value: -7, to: nowDate)!
        let modifiedYear = Calendar.current.date(byAdding: .year, value: -1, to: nowDate)!
        
        let isDateYesterday = calendar.isDateInYesterday(date)
        let isDateToday = calendar.isDateInToday(date)
                        
        // 一年以上前の場合(年、日付を表示)
        if modifiedYear >= date {
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: date)
        }
        
        // 一週間以上の場合(日付を表示)
        if modifiedDate >= date {
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
        
        // 今日かどうか(時間を表示)
        if isDateToday {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        // 昨日かどうか
        if isDateYesterday {
            return "昨日"
        } else {
            // 曜日表示
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
}

