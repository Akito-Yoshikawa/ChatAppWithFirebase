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
    
    public var partherUser: User!
            
    @IBOutlet weak var userDetailStackView: UIStackView!

    @IBOutlet weak var userImage: UIImageView!
                
    @IBOutlet weak var userLabel: UILabel!
        
    @IBOutlet weak var userId: UILabel!

    @IBOutlet weak var commentLabelContent: UILabel!
    
    @IBOutlet weak var chatStartButton: UIButton!
        
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userDetailStackView.layer.cornerRadius = 15
        userImage.layer.cornerRadius = 75
        
        chatStartButton.layer.cornerRadius = 15
        
        closeButton.layer.cornerRadius = 15
        
        userLabel.text = partherUser?.username
        userImage?.loadImage(with: partherUser?.profileImageUrl ?? "")

        commentLabelContent.text = partherUser.selfIntroduction
        
        userId.text = "@" + partherUser.userID
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
                
        ChatRoomAccessor.sharedManager.setChatRoom(docData: docData) { [weak self] (error) in
            guard let self = self else { return }

            if let _ = error {
                print("ChatRoom情報の保存に失敗しました。")
                return
            }
            print("ChatRoom情報の保存に成功しました。")
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func userDetailClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
