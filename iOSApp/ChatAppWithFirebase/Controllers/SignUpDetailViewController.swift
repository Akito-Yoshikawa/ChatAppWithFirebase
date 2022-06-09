//
//  SignUpDetailViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/10.
//

import Foundation
import UIKit

class SignUpDetailViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileImageButton: UIButton!
    
    
    @IBOutlet weak var userIdTextField: UITextField!
        
    @IBOutlet weak var userIntroductionTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpViews()
    }
    
    private func setUpViews() {
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
    }
    
    private func goChatListView() {
        let nav = self.presentingViewController as! UITabBarController
        let selectedVC = nav.selectedViewController as! UINavigationController
        let chatListViewController = selectedVC.viewControllers[selectedVC.viewControllers.count-1] as? ChatListViewController
        chatListViewController?.reloaChatListViewController()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tappedProfileTappedBtn(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true

        self.present(imagePickerController, animated: true, completion: nil)
    }

    
    @IBAction func tappedRegister(_ sender: Any) {
        // TODO: 全て設定されていなかったらアラート表示(あとで設定を行いますか？ OK 押したらチャットリスト画面)
        
        // 保存してチャットリスト画面に遷移
        
        // TODO: userimage画像更新、なければしない
        // TODO: ユーザーID追加、使用可能か確認して、あったら追加
        // TODO: 自己紹介文あったら追加
        
        let image = profileImageButton.imageView?.image ?? UIImage(named: "freeImage01")
                
        self.goChatListView()
    }
    
    @IBAction func tappedSkip(_ sender: Any) {
        // 保存しないでチャットリスト画面遷移
        self.goChatListView()
    }
}

extension SignUpDetailViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        profileImageButton.setTitle("", for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
    }
}
