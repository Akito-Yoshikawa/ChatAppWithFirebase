//
//  LoginViewController.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/15.
//

import Foundation
import UIKit
import Firebase
import PKHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!
        
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var dontHaveAccountButton: UIButton!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    @IBAction func tappedLoginButton(_ sender: Any) {
        guard let email = self.emailTextField.text else {
            return
        }
        
        guard let password = self.passwordTextField.text else {
            return
        }
        
        HUD.show(.progress)

        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("ログインに失敗しました。\(err)")
                self.showSingleBtnAlert(title: "ログインに失敗しました。")
                HUD.hide()
                return
            }
            
            HUD.hide()
            print("ログインに成功しました。")
            
            let nav = self.presentingViewController as! UINavigationController
            let chatListViewController = nav.viewControllers[nav.viewControllers.count-1] as? ChatListViewController
            chatListViewController?.fetchChatroomsInfoFromFirestore()
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func tappedDontHaveAccountButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
        
    private func setUpViews() {
        emailTextField.delegate = self
        passwordTextField.delegate = self

        loginButton.layer.cornerRadius = 8
        loginButton.isEnabled = false
        loginButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? false

        if emailIsEmpty || passwordIsEmpty {
            loginButton.isEnabled = false
            loginButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        } else {
            loginButton.isEnabled = true
            loginButton.backgroundColor = .rgb(red: 0, green: 180, blue: 0)
        }
    }
}
