//
//  Extensions.swift
//  GameOfChats
//
//  Created by Ricky Avina on 4/10/17.
//  Copyright © 2017 InternTeam. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCache(withUrlString urlString: String){
        
        self.image = nil
        
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage{
            self.image = cachedImage
            return
        }
        
        // otherwise fire off new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            // download hit an error
            if error != nil {
                print(error as! NSError)
                return
            }
            
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!){
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                }
            }
            
        }).resume()
    }
}

extension String {
    
    func cutStringOff(at numCharacters: Int) -> String {
        var currentString = self
        
        if currentString.characters.count >= numCharacters {
            let index = currentString.index(currentString.startIndex, offsetBy: numCharacters)
            currentString = "\((currentString.substring(to: index)))..."
        }
        
        return currentString
    }
    
}
