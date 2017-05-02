//
//  NewMessageController.swift
//  GameOfChats
//
//  Created by Ricky Avina on 4/8/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class NewMessageController: UITableViewController {
    
    let cellId = "cellId"
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    func fetchUser(){
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.id = snapshot.key

                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        
        if let name = user.name {
            cell.textLabel?.text = name.cutStringOff(at: 18)
        }
    
        cell.detailTextLabel?.text = "\(user.email!)"

        if let profileImageUrl = user.profileImageUrl {
            cell.profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
           /* let url = URL(string: profileImageUrl)
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                
                // download hit an error
                if error != nil {
                    print(error as! NSError)
                    return
                }
                
                DispatchQueue.main.async {
                    cell.profileImageView.image = UIImage(data: data!)
                }
                
            }).resume()*/
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user)
        })
    }
}
