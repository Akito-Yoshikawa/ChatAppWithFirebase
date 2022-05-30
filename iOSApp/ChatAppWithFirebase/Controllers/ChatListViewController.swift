//
//  ChatListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/04/25.
//

import UIKit
import Firebase
import Nuke
import RealmSwift

class ChatListViewController: UIViewController {
        
    private let cellId = "cellId"
    private var chatRoomListener: ListenerRegistration?
    
    private var realmChatRoom = [ChatRoom]()
    
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
        
        sortChatRoomList()
        fetchLoginUserInfo()
    }
    
    ///  chatRoomListのソートを行う
    public func sortChatRoomList() {
        let realmChatRoom = ChatRoomAccessor.shardInstance.getAll()

        if let localRealmChatRoom = realmChatRoom {
            self.realmChatRoom = localRealmChatRoom.sorted { m1, m2 in
                let m1Date = m1.chatListdateReturn()
                let m2Date = m2.chatListdateReturn()
                return m1Date > m2Date
            }
        }
    }
    
    public func fetchChatroomsInfoFromFirestore() {
        chatRoomListener?.remove()
        if !ChatRoomAccessor.shardInstance.deleteAll() {
            print("DBの削除に失敗しました。")
        }

        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms").addSnapshotListener({ (snapshots, err) in
            if let err = err {
                print("ChatRooms情報の取得に失敗しました。\(err)")
                self.showSingleBtnAlert(title: "チャットリスト情報の取得に失敗しました。")
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

        let chatRoomMembers = chatRoom.transformToJSON()

        let isConatin = chatRoomMembers.contains(uid)
        
        if !isConatin {
            return
        }

        chatRoomMembers.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                    if let err = err {
                        print("ユーザーの情報に取得に失敗しました。\(err)")
                        self.showSingleBtnAlert(title: "チャットリスト情報の取得に失敗しました。")
                        return
                    }
                    
                    guard let dic = userSnapshot?.data(),
                          let userDocumentID = userSnapshot?.documentID else {
                        return
                    }
                    
                    let user = User(dic: dic)
                    user.uid = userDocumentID
                    
                    chatRoom.partnerUser = user
                    
                    let chatroomId = chatRoom.documentId
                    let latestMessageId = chatRoom.latestMessageId
                    
                    if latestMessageId.isEmpty {
                        // チャットルームDB保存
                        if !ChatRoomAccessor.shardInstance.set(data: chatRoom) {
                            print("Realmに保存に失敗しました。")
                            return
                        }
                        
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err)  in
                        if let err = err {
                            print("最新情報の取得に失敗しました。\(err)")
                            self.showSingleBtnAlert(title: "チャットリスト情報の取得に失敗しました。")
                            return
                        }
                        
                        guard let dic = messageSnapshot?.data() else {
                            return
                        }
                        let message = Message(dic: dic)
                        chatRoom.latestMessage = message
                        
                        switch documentChange.type {
                        case .modified:
                            // チャットルームが変更されたら、変更された前のチャットルームを更新する
                            if !ChatRoomAccessor.shardInstance.set(data: chatRoom, updatePolicy: .modified) {
                                print("Realmに保存に失敗しました。")
                                return
                            }
                        default: break
                        }
                                                
                        // チャットルームDB保存
                        if !ChatRoomAccessor.shardInstance.set(data: chatRoom) {
                            print("Realmに保存に失敗しました。")
                            return
                        }
                        
                        self.sortChatRoomList()

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
        let storyboar = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboar.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        let nav = UINavigationController(rootViewController: loginViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion:
        nil)
    }
    
    private func setupViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self

        navigationController?.changeNavigationBarBackGroundColor()
        
        navigationItem.title = "トーク"

        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogoutButton))
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    @objc private func tappedLogoutButton() {

        do {
            try Auth.auth().signOut()

            chatRoomListener?.remove()
            
            chatListTableView.reloadData()

            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。\(error)")
        }
        
    }
        
    private func fetchLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Firestore.firestore().collection("users").document(uid).getDocument { [self] (snapshot, err) in

            if let err = err {
                print("ユーザーの情報に取得に失敗しました。\(err)")
                return
            }
 
            guard let snapshot = snapshot,
            let dic = snapshot.data() else {
                return
            }

            let user = User(dic: dic)
            user.uid = uid
            
            if !UserAccessor.shardInstance.set(data: user) {
                print("Realmに保存に失敗しました。")
                return
            }
            
            self.user = UserAccessor.shardInstance.getByID(id: uid)
        }
    }
    
}


// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realmChatRoom.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! ChatListTableViewCell
        cell.chatroom = realmChatRoom[indexPath.row]
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        
        chatRoomViewController.user = user
        chatRoomViewController.chatRoom = realmChatRoom[indexPath.row]
        
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

