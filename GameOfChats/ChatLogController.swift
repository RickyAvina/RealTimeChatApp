//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Ricky Avina on 4/17/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User?{
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    func observeMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else { return }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else { return }
                
                self.messages.append(Message(dictionary: dictionary))
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    // scroll to last index
                    self.scrollToBottom()
                }
            })
        }, withCancel: nil)
    }
    
    private func scrollToBottom(){
        let indexPath = IndexPath(item: self.messages.count-1, section: 0)
        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.removeObserver(self)
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    func handleUploadTap(){
        let imagePickerController = UIImagePickerController()
        present(imagePickerController, animated: true, completion: nil)
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            // selected a video
            handleVideoSelected(forURL: videoUrl)
        } else {
            // selected an image
            handleImageSelected(forInfoDictionary: info)
        }
        
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelected(forURL url: URL){
        let filename = UUID().uuidString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(filename).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Failed to upload video: ", (error! as Error))
                return
            }
            
            if let videoUrl = (metadata! as FIRStorageMetadata).downloadURL()?.absoluteString {
                if let thumbnailImage = self.getThumbnailImage(forFileUrl: url){
                    
                    self.uploadToFirebaseStorage(using: thumbnailImage, completion: { (imageUrl) in
                         
                        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl]
                        self.sendMessages(with: properties)
                    })
                }
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
        
    }
    
    private func getThumbnailImage(forFileUrl fileUrl: URL) -> UIImage? {
        
        let asset = AVURLAsset(url: fileUrl , options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)

        do {
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(1, 160), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
            
        } catch let error{
            print("error", error)
        }
        
        return nil
    }
    
    private func handleImageSelected(forInfoDictionary info: [String: Any]){
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorage(using: selectedImage, completion: { (imageUrl) in
                self.sendMessage(with: imageUrl, image: selectedImage)
            })
        }
    }
    
    private func uploadToFirebaseStorage(using image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = UUID().uuidString
        let ref = FIRStorage.storage().reference().child("messages_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Failed to upload image: " , error!)
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString{
                    completion(imageUrl)
                }
            })
        }
        
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    var timer: Timer?
    
    func handleKeyboardDidShow(){
        attemptScrollToBottom()
    }
    
    func attemptScrollToBottom(){
        if messages.count > 0 {
            scrollToBottom()
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification){
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue as Double
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func handleKeyboardWillShow(notification: NSNotification){
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue as CGRect
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue as Double
        
        // move keyboard up
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            height = estimateFrame(for: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            // h1 / w1 = h2 / w2        h1 = h2 / w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    private func estimateFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.message = message
        
        cell.textView.text = message.text
        
        setupCell(withCell: cell, message: message)
        
        if let text = message.text {
            // text message
            cell.bubbleWidthAnchor?.constant = estimateFrame(for: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil { // image message
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    private func setupCell(withCell cell: ChatMessageCell, message: Message){
        if let profileImageUrl = self.user?.profileImageUrl{
            cell.profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = ChatMessageCell.lightGreyColor
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCache(withUrlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    var containerViewBottomAnchor : NSLayoutConstraint?
    
    func handleSend(){
        let properties: [String: Any] = ["text": inputContainerView.inputTextField.text!]
        sendMessages(with: properties)
    }
    
    private func sendMessage(with imageUrl: String,  image: UIImage){
        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessages(with: properties)
    }
    
    private func sendMessages(with properties: [String: Any]){
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        
        var values: [String: Any] = ["toId": toId, "fromId": fromId, "timestamp": timestamp]
        
        // append optional properties
        // key $0, value $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error as! NSError)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        })
        
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var imageView: UIImageView?
    
    func performZoomIn(for imageView: UIImageView){
        self.imageView = imageView
        self.imageView?.isHidden = true
        
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = imageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleZoomOutSwipe))
        swipeRecognizer.direction = UISwipeGestureRecognizerDirection.down
        zoomingImageView.addGestureRecognizer(swipeRecognizer)
        
        if let keyWindow = UIApplication.shared.keyWindow {
            self.blackBackgroundView = UIView(frame: keyWindow.frame)
            self.blackBackgroundView?.backgroundColor = UIColor.black
            self.blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(self.blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: { (completed) in
                // do nothing
            })
        }
    }
    
    func handleZoomOutSwipe(swipeGesture: UISwipeGestureRecognizer){
        if let zoomOutImageView = swipeGesture.view {
            
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.imageView?.isHidden = false
            })
        }
        
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer){
        if let zoomOutImageView = tapGesture.view {
            
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.imageView?.isHidden = false
            })
        }
    }
}
