//
//  ImageGallery.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation

class ImageGallery {
	
	var galleryName: String = "Gallery"
	var imageTasks: [ImageTask] = []
	
	convenience init(galleryName: String) {
		self.init()
		self.galleryName = galleryName
	}
	
}
