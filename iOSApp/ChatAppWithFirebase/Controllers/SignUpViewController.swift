//
//  SignUpViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/05.
//

import UIKit
import Firebase
import PKHUD

class SignUpViewController: UIViewController, UINavigationControllerDelegate {
        
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!
    
    @IBAction func tappedRegisterButton(_ sender: Any) {
        
        // FIXME: デフォルトイメージを登録(仮画像)
        let image = UIImage(named: "freeImage01")

        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else {
            return
        }
        
        HUD.show(.progress)
        
        let fileName = NSUUID().uuidString
        
        ProfileImageAccessor.sharedManager.profileImagePutData(fileName: fileName, uploadImage: uploadImage) { [weak self]
            (error) in
            guard let self = self else { return }

            if let _ = error {
                self.showSingleBtnAlert(title: "アカウントの作成に失敗しました。")
                HUD.hide()
                return
            }
                        
            ProfileImageAccessor.sharedManager.downloadImageReturnURLString(fileName: fileName) { [weak self] (result) in
                guard let self = self else { return }

                switch result {
                case .success(let urlString):
                    guard let urlString = urlString else {
                        self.showSingleBtnAlert(title: "アカウントの作成に失敗しました。")
                        HUD.hide()
                        return
                    }
                                        
                    self.createUserToFirestore(profileImageUrl: urlString)

                case .failure(_):
                    self.showSingleBtnAlert(title: "アカウントの作成に失敗しました。")
                    HUD.hide()
                    return
                }
            }
        }
    }
    
    @IBAction func tappedAlreadyHaveAccountButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
    }

    private func setUpViews() {
        
        registerButton.layer.cornerRadius = 12
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self

        registerButton.isEnabled = false
        registerButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
    }
    
    private func createUserToFirestore(profileImageUrl: String) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let username = usernameTextField.text else {
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in

            if let err = err {
                print("Auth情報の保存に失敗しました。\(err)")
                self.showSingleBtnAlert(title: "アカウントの作成に失敗しました。")
                HUD.hide()
                return
            }
            
            print("Auth情報の保存に成功しました。")
            
            guard let uid = res?.user.uid else {
                return
            }
            
            let docData = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "profileImageUrl": profileImageUrl
            ] as [String: Any]
                        
            UserAccessor.sharedManager.setUserData(memberUid: uid, docData: docData) { [weak self]
                (error) in

                guard let self = self else { return }

                if let _ = error {
                    self.showSingleBtnAlert(title: "アカウントの作成に失敗しました。")
                    HUD.hide()
                    return
                }
                
                HUD.hide()
                
                let storyboard = UIStoryboard(name: "SignUpDetail", bundle: nil)
                let signUpDetailVC = storyboard.instantiateViewController(withIdentifier: "SignUpDetailViewController") as! SignUpDetailViewController
                signUpDetailVC.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(signUpDetailVC, animated: true)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? false
        
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = .rgb(red: 0, green: 180, blue: 0)
        }
    }
}
