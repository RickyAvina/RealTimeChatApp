//
//  LoginController+handlers.swift
//  GameOfChats
//
//  Created by Ricky Avina on 4/9/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit
import Firebase

extension LoginController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleSelectProfileImageView(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancelled picker")
        dismiss(animated: true, completion: nil)
    }
    
    func handleRegister(){
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: {
            user, error in
            
            if error != nil {
                print(error!)
                return
            }
            
            guard let uid = user?.uid else  {
                print("UID already in use!")
                return
            }
            
            // successful authentication
            let imageName = NSUUID().uuidString
            let storargeRef = FIRStorage.storage().reference().child("profile_images").child(imageName)
            
            // compression
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.08) {
    
                storargeRef.put(uploadData, metadata: nil, completion: {
                    (metadata, error) in
                    if error != nil {
                        print(error as! NSError)
                        return
                    }
                    
                    if let profileImageUrl  = metadata?.downloadURL()?.absoluteString{
                        let values : [String: Any] = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        self.registerUserIntoDatabase(with: uid, values: values)

                    }
                  //  print(metadata! as FIRStorageMetadata)
                })
            }
        })
    }
    
    private func registerUserIntoDatabase(with uid: String, values: [String:Any]){
        let reference = FIRDatabase.database().reference()
        let usersReference = reference.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: {
            err, ref in
            
            if err != nil {
                print(err!)
                return
            }
            
            //self.messagesController.navigationItem.title = values["name"] as? String
            let user = User()
            // this setter potentially crashes if keys don't match
            user.setValuesForKeys(values)
            self.messagesController.setupNavBar(with: user)
            self.dismiss(animated: true, completion: nil)
        })
    }
}
