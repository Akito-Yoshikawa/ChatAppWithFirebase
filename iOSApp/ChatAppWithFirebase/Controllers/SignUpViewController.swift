//
//  SignUpViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/05.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var profileImageButton: UIButton!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!
        
    @IBAction func tappedProfileTappedBtn(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true

        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func tappedRegisterButton(_ sender: Any) {
        
        guard let image = profileImageButton.imageView?.image else {
            return
        }

        guard let uploadImage = image.jpegData(compressionQuality: 0.3) else {
            return
        }
        
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)

        storageRef.putData(uploadImage, metadata: nil) { (matadata,err) in
            if let err = err {
                print("Firestorageへの情報の保存に失敗しました。\(err)")
                return
            }
            print("Firestorageへの情報の保存に成功しました。")

            storageRef.downloadURL { (url, err) in
                if let err = err {
                        print("Firestorageからのダウンロードに失敗しました。\(err)")
                    return
                }
                
                guard let urlString = url?.absoluteString else {
                    return
                }
                
                self.createUserToFirestore(profileImageUrl: urlString)
            }
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
        
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
                        

            Firestore.firestore().collection("users").document(uid).setData(docData) {
                (err) in
                
                if let err = err {
                    print("Firestoreへの保存に失敗しました。\(err)" )
                }
                
                print("Firestoreへの情報の保存が成功しました。")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

extension SignUpViewController: UIImagePickerControllerDelegate {
    
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
