//
//  ChatRoomTableViewCell.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/04/27.
//

import UIKit

class ChatRoomTableViewCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            if let message = message {
                let width = estimateFrameForTextView(text: message.message).width + 20
                messageTextVIewConstraint.constant = width
                
                messageTextView.text = message.message
                dateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
            }
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
        
    @IBOutlet weak var messageTextVIewConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        userImageView.layer.cornerRadius = 30
        messageTextView.layer.cornerRadius = 15
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
    }
    
    
    private func estimateFrameForTextView(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], context: nil)
        
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
