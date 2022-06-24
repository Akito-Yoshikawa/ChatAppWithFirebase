//
//  ChatListViewController.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/04/25.
//

import UIKit
import Firebase
import Nuke

class ChatListViewController: UIViewController {
        
    private let cellId = "cellId"
    
    private var chatRooms = [ChatRoom]()

    private var currentUser: User? {
        didSet {
            navigationItem.title = currentUser?.username
        }
    }
        
    @IBOutlet weak var promptMessageLabel: UILabel!
        
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        setupViews()
        confirmLoggedInUser()
     
        reloaChatListViewController()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let currentUser = currentUser,
           let userAccessorCurrentUser = UserAccessor.sharedManager.currentUser {
            if userAccessorCurrentUser.userSameConfirmation(confirmationUser: currentUser) {
                // user取得
                self.currentUser = UserAccessor.sharedManager.currentUser
            }
        }

    }
    
    public func reloaChatListViewController() {
        UserAccessor.sharedManager.setCurrentUser() { [weak self] (result) in
            guard let self = self else { return }
            if !result {
                print("CurrentUserのSetに失敗しました。")
            }
            self.currentUser = UserAccessor.sharedManager.returnCurrentUser()
            
            self.fetchChatroomsInfoFromFirestore()
        }
    }
            
    public func fetchChatroomsInfoFromFirestore() {
        guard let currentUser = self.currentUser,
                let currentUserUid = currentUser.uid else {
                    return
                }
        
        ChatRoomAccessor.sharedManager.getChatRoomsAddSnapshotListener(listenerName: .chatListViewController, cureentUid: currentUserUid) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let result):
                if let collection = result {
                    
                    // 取得したチャットルームの数が0件の場合はメッセージを表示する
                    if collection.count <= 0 {
                        self.promptMessageLabel.lineBreakMode = .byWordWrapping
                        self.promptMessageLabel.isHidden = false
                        return
                    } else {
                        self.promptMessageLabel.isHidden = true
                    }
                    
                    collection.forEach({ (documentChange) in
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    })
                }
            case .failure(_):
                self.showSingleBtnAlert(title: "チャットリスト情報の取得に失敗しました。")
            }
        }
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        
        let dic = documentChange.document.data()
        var chatRoom = ChatRoom.init(dic: dic)
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
                
                // ユーザー情報の取得
                UserAccessor.sharedManager.getApecificUser(memberUid: memberUid) {
                    [weak self] (result) in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let result):
                        guard let dic = result?.data(),
                              let userDocumentID = result?.documentID else {
                                  return
                              }
                        
                        var user = User(dic: dic)
                        user.uid = userDocumentID
                        
                        chatRoom.partnerUser = user
                        
                        guard let chatroomId = chatRoom.documentId else {
                            return
                        }
                        let latestMessageId = chatRoom.latestMessageId
                        
                        if latestMessageId.isEmpty {
                            for localChatRoom in self.chatRooms {
                                if localChatRoom.documentId == chatRoom.documentId {
                                    return
                                }
                            }
                            
                            self.chatRooms.append(chatRoom)
                            
                            self.chatRoomsSort()
                            
                            self.chatListTableView.reloadData()
                            return
                        }
                        
                        // チャットルーム情報の取得
                        MessageAccessor.sharedManager.getMessage(chatRoomId: chatroomId, latestMessageId: latestMessageId) {
                            [weak self] (result) in
                            guard let self = self else { return }

                            switch result {
                            case .success(let result):
                                guard let dic = result?.data() else {
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
                                
                                self.chatRoomsSort()
                                
                                self.chatListTableView.reloadData()
                                
                            case .failure(_):
                                self.showSingleBtnAlert(title: "メッセージの取得に失敗しました。")
                            }
                        }
                    case .failure(_):
                        self.showSingleBtnAlert(title: "ユーザー情報の取得に失敗しました。")
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

            ChatRoomAccessor.sharedManager.removeAllChatRoomListener()
            
            UserAccessor.sharedManager.removeUserListener()

            chatRooms = []
            
            chatListTableView.reloadData()

            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。\(error)")
        }
        
    }
        
    ///  ローカルchatRoomsのソートを最新の時間で行う
    private func chatRoomsSort() {
        // 最新順に上から並び替える
        self.chatRooms.sort { (m1, m2) -> Bool in
            let m1Date = m1.chatListdateReturn()
            let m2Date = m2.chatListdateReturn()
            return m1Date > m2Date
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
        
        chatRoomViewController.user = currentUser
        let chatRoom = chatRooms[indexPath.row]
        chatRoomViewController.chatRoom = chatRoom

        // チャットルーム画面左上の文字を相手の名前を表示する
        let backItem  = UIBarButtonItem(title: chatRoom.partnerUser?.username, style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem

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

