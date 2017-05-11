//
//  ChatInputContainerView.swift
//  GameOfChats
//
//  Created by Ricky Avina on 5/10/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    var chatLogController: ChatLogController?{
        didSet{
            sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
            
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    let sendButton = UIButton(type: .system)
    
    lazy var inputTextField : UITextField = {
        let inputTextF = UITextField()
        inputTextF.placeholder = "Enter message..."
        inputTextF.translatesAutoresizingMaskIntoConstraints = false
        inputTextF.delegate = self
        return inputTextF
    }()
    
    let uploadImageView: UIImageView = {
        let uView = UIImageView()
        uView.isUserInteractionEnabled = true
        uView.image = UIImage(named: "photos")
        uView.translatesAutoresizingMaskIntoConstraints = false
        return uView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        addSubview(self.inputTextField)
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatLogController?.handleSend()
        return true
    }
}
