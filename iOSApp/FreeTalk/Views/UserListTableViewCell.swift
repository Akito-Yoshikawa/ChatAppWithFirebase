//
//  UserListTableViewCell.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/05/26.
//

import Foundation
import UIKit

class UserListTableViewCell: UITableViewCell {
    
    var user: User? {
        didSet {
            userNameLabel.text = user?.username

            userImageView.loadImage(with: user?.profileImageUrl ?? "")
        }
    }
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 32.5
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
