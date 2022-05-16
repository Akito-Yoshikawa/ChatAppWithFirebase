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
        
        loginButton.layer.cornerRadius = 8
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
}
