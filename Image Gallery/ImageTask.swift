//
//  Image.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/27/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation
import UIKit

class ImageTask: Hashable, Codable {
    
    private static var identifier: Int = 0
    
    var identifier: Int
    
    var hashValue: Int {
        return identifier
    }
    
    static func == (lhs: ImageTask, rhs: ImageTask) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var url: URL?
    var aspectRatio: CGFloat?
	
    init() {
        identifier = ImageTask.makeIdentifier()
    }
	
    private static func makeIdentifier() -> Int {
        identifier += 1
        return identifier
    }
    
}
