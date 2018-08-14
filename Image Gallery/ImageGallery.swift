//
//  ImageGallery.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation
import UIKit

struct ImageGallery: Codable {
	
    struct ImageTask: Codable {
        var url: URL
        var aspectRatio: CGFloat
    }
    
	var imageTasks: [ImageTask]
    
    var jsonData: Data? {
        return try? JSONEncoder().encode(self)
    }
	
    init(imageTasks: [ImageTask]) {
        self.imageTasks = imageTasks
    }
	
		
}
