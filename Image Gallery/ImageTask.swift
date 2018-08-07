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
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		identifier = try container.decode(Int.self, forKey: .identifier)
		url = try container.decode(URL?.self, forKey: .url)
		aspectRatio = try container.decode(CGFloat?.self, forKey: .aspectRatio)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(identifier, forKey: .identifier)
		try container.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
		try container.encodeIfPresent(url, forKey: .url)
	}
	
    private static func makeIdentifier() -> Int {
        identifier += 1
        return identifier
    }
	
	private enum CodingKeys: String, CodingKey {
		case identifier = "identifier"
		case url = "url"
		case aspectRatio = "aspectRatio"
	}
    
}
