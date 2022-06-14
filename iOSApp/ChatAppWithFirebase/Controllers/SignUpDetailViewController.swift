//
//  SignUpDetailViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/10.
//

import Foundation
import UIKit
import PKHUD
import Firebase

class SignUpDetailViewController: UIViewController, UINavigationControllerDelegate {
    
    private var isUserIdUnique = false {
        // 値の監視
        didSet {
            if isUserIdUnique {
                // アラート表示
                self.showSingleBtnAlert(title: "利用可能です。") {
                    // ボタンタイトル利用可能変更
                    self.userIdUniqueCheckButton.setTitle("利用可能です", for: .normal)
                    // ボタン選択させない
                    self.userIdUniqueCheckButton.isEnabled = false
                }
            } else {
                // ボタンタイトル利用可能変更
                self.userIdUniqueCheckButton.setTitle("利用可能か確認", for: .normal)
                // ボタン選択させない
                self.userIdUniqueCheckButton.isEnabled = true
            }
        }
    }
    
    @IBOutlet weak var profileImageButton: UIButton!
    
    @IBOutlet weak var userIdUniqueCheckButton: UIButton!
    
    @IBOutlet weak var userIdTextField: UITextField!
        
    @IBOutlet weak var user: UIButton!
    
    @IBOutlet weak var userIntroductionTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpViews()
    }
    
    private func setUpViews() {
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor

        userIdTextField.delegate = self
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
    
    @IBAction func tappedUserIdUniqueCheck(_ sender: Any) {
        guard let userId = self.userIdTextField.text,
                  !userId.isEmpty else {
                      self.showSingleBtnAlert(title: "ユーザーIDを入力してください。")
                      return
              }
        
        // 入力されたuserIDがユニークかどうかチェック
        UserAccessor.sharedManager.checkUniqueUserId(userId: userId) {
            (isUnique) in
            
            if isUnique {
                // ユニークであるため登録おっけ
                self.isUserIdUnique = true
            } else {
                // ユニークではないため登録NG
                self.isUserIdUnique = false
            }
        }
    }
    
    @IBAction func tappedRegister(_ sender: Any) {
        // 全て設定されていなかったらアラート表示
        guard let userId = self.userIdTextField.text,
              let userIntroduction = self.userIntroductionTextField.text else {
                  return
              }
        if self.profileImageButton.imageView?.image == nil && userId.isEmpty && userIntroduction.isEmpty {

            // アカウントの設定はあとで行いますか？はい、いいえを表示。「はい」だったらチャットリスト画面へ、「いいえ」だったら何もしない
            self.showCommonlableAlert(title: "アカウントの設定はあとで行いますか？", message: "", okActionTitle: "はい", okHandler: {
                self.goChatListView()
            }, cancelActionTitle: "いいえ") {}
            return
        }
        
        var docData = [String: Any]()

        // ユーザーID追加、使用可能か確認して、あったら追加
        if !userId.isEmpty {
            // ユーザーIDが設定されていたら,それが使用可能かチェックしてまだチェックしていなかったらアラート表示。使用可能な場合はセットする
            if !isUserIdUnique {
                self.showSingleBtnAlert(title: "ユーザーIDが利用可能か確認ボタンを押してください。")
                return
            }
            docData["userID"] = userId
        }

        // 自己紹介文あったら追加
        if !userIntroduction.isEmpty {
            docData["selfIntroduction"] = userIntroduction
        }
        
        // インジケーター表示
        HUD.show(.progress)
        
        // userimage画像更新、なければしない
        guard let profileImageUrl = profileImageButton.imageView?.image,
              let uploadImage = profileImageUrl.jpegData(compressionQuality: 0.3) else {
                  // Userの更新
                  self.updateUserToFirestore(docData: docData)
                  return
              }

        // userimage画像更新
        // プロフィール画像のアップロード
        self.uploadProfileImage(uploadImage) { [weak self]
            (urlString) in
            
            guard let urlString = urlString else {
                self?.showSingleBtnAlert(title: "アカウントの設定に失敗しました。")
                return
            }
            
            // プロフィール画像URL追加
            docData["profileImageUrl"] = urlString
            
            // Userの更新
            self?.updateUserToFirestore(docData: docData)
        }
    }
    
    @IBAction func tappedSkip(_ sender: Any) {
        // 保存しないでチャットリスト画面遷移
        self.goChatListView()
    }
        
    private func uploadProfileImage(_ uploadImage: Data, completion: @escaping (String?) -> Void) {
        let fileName = "\(NSUUID().uuidString).jpg"
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        ProfileImageAccessor.sharedManager.profileImagePutData(fileName: fileName, uploadImage: uploadImage, metadata: metaData) { (error) in

            if let _ = error {
                completion(nil)
                return
            }
                        
            ProfileImageAccessor.sharedManager.downloadImageReturnURLString(fileName: fileName) { (result) in

                switch result {
                case .success(let urlString):
                    guard let urlString = urlString else {
                        completion(nil)
                        return
                    }
                    
                    completion(urlString)
                case .failure(_):
                    completion(nil)
                    return
                }
            }
        }
    }
    
    private func updateUserToFirestore(docData: [String: Any]) {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.showSingleBtnAlert(title: "アカウントの設定に失敗しました。")
            HUD.hide()
            return
        }
                    
        UserAccessor.sharedManager.setUserData(memberUid: uid, docData: docData, isMerge: true) { [weak self]
            (error) in

            guard let self = self else { return }

            if let _ = error {
                self.showSingleBtnAlert(title: "アカウントの設定に失敗しました。")
                HUD.hide()
                return
            }
            
            HUD.hide()
            
            print("アカウントの設定に成功しました")
            
            self.goChatListView()
        }
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

extension SignUpDetailViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {

        if let _ = userIdTextField.text {
            self.isUserIdUnique = false
            return
        }
    }
}
