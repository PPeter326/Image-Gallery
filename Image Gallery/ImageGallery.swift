//
//  ImageGallery.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation

class ImageGallery: Hashable {
	
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
	
	convenience init(galleryName: String) {
		self.init()
		self.galleryName = galleryName
	}
	
	private static func makeIdentifier() -> Int {
		identifier += 1
		return identifier
	}
	
}
