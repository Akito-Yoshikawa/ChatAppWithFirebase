//
//  ChatRoomTableViewCell.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/04/27.
//

import UIKit
import Firebase

class ChatRoomTableViewCell: UITableViewCell {
    
    var message: Message? {
        didSet {
//            if let message = message {
//                let width = estimateFrameForTextView(text: message.message).width + 20
//                messageTextVIewConstraint.constant = width
//
//                partnarMessageTextView.text = message.message
//                partnarDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
//            }
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var partnarMessageTextView: UITextView!
    @IBOutlet weak var myMessageTextView: UITextView!
    
    @IBOutlet weak var partnarDateLabel: UILabel!
    @IBOutlet weak var myDateLabel: UILabel!
        
    @IBOutlet weak var messageTextViewWidthConstraint: NSLayoutConstraint!
        
    @IBOutlet weak var myMessageTextViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        userImageView.layer.cornerRadius = 30
        partnarMessageTextView.layer.cornerRadius = 15
        
        myMessageTextView.layer.cornerRadius = 15
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        checkWhichUserMessage()
    }
    
    private func checkWhichUserMessage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        if uid == message?.uid {
            partnarMessageTextView.isHidden = true
            partnarDateLabel.isHidden = true
            userImageView.isHidden = true
            
            myMessageTextView.isHidden = false
            myDateLabel.isHidden = false
            
            if let message = message {
                myMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 20
                myMessageTextViewWidthConstraint.constant = width
                
                myDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
            }

            
        } else {
            partnarMessageTextView.isHidden = false
            partnarDateLabel.isHidden = false
            userImageView.isHidden = false
            
            myMessageTextView.isHidden = true
            myDateLabel.isHidden = true
            userImageView.loadImage(with: message?.partnerUser?.profileImageUrl ?? "")
            
            if let message = message {
                let width = estimateFrameForTextView(text: message.message).width + 20
                messageTextViewWidthConstraint.constant = width
                
                partnarMessageTextView.text = message.message
                partnarDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
            }

        }
    }
    
    
    private func estimateFrameForTextView(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
