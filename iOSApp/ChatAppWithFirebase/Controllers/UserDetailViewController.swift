//
//  UserDetailViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/31.
//

import Foundation
import UIKit
import Firebase

class UserDetailViewController: UIViewController {
    
    public var partherUser: User?
            
    @IBOutlet weak var userDetailStackView: UIStackView!

    @IBOutlet weak var userImage: UIImageView!
                
    @IBOutlet weak var userLabel: UILabel!
        
    @IBOutlet weak var commentLabelContent: UILabel!
    
    @IBOutlet weak var chatStartButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userDetailStackView.layer.cornerRadius = 15
        userImage.layer.cornerRadius = 75
        
        chatStartButton.layer.cornerRadius = 15
        
        userLabel.text = partherUser?.username
        userImage?.loadImage(with: partherUser?.profileImageUrl ?? "")

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @IBAction func chatStart(_ sender: Any) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let partherUid = self.partherUser?.uid else {
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
                        
            print("ChatRoom情報の保存に成功しました。")
        
            self.dismiss(animated: true, completion: nil)
        }
    }
}
