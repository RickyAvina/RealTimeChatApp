//
//  Message.swift
//  GameOfChats
//
//  Created by Ricky Avina on 4/19/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    func chatPartnerId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }
    
    init(dictionary: [String: Any]){
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        toId = dictionary["toId"] as? String
        fromId = dictionary["fromId"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
    }
}
