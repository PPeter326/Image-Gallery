//
//  ImageGallery.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation

class ImageGallery: Hashable, Codable {
	
	private static var identifier: Int = 0
	
	private var identifier: Int
	
	static func == (lhs: ImageGallery, rhs: ImageGallery) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	var hashValue: Int {
		return identifier
	}
	
	var galleryName: String = "Gallery"
	var imageTasks: [ImageTask] = []
	
	init() {
		// Incrementing identifier for every ImageGallery instance, to provide unique hash value
		identifier = ImageGallery.makeIdentifier()
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		identifier = try container.decode(Int.self, forKey: .identifier)
		galleryName = try container.decode(String.self, forKey: .galleryName)
		imageTasks = try container.decode([ImageTask].self, forKey: .imageTasks)
	}
	convenience init(galleryName: String) {
		self.init()
		self.galleryName = galleryName
	}
	
	private static func makeIdentifier() -> Int {
		identifier += 1
		return identifier
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(identifier, forKey: .identifier)
		try container.encode(galleryName, forKey: .galleryName)
		try container.encode(imageTasks, forKey: .imageTasks)
	}
	
	private enum CodingKeys: String, CodingKey {
		case identifier = "identifier"
		case galleryName = "galleryName"
		case imageTasks = "imageTasks"
	}
	
}
