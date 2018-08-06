//
//  TaskHandler.swift
//  Image Gallery
//
//  Created by Peter Wu on 8/6/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation

class TaskHandler {
	
	private var handler: (ImageTask) -> Void
	
	init(handler: @escaping (ImageTask) -> Void) {
		self.handler = handler
	}
	
	func process(imageTask: ImageTask) {
		if imageTask.url != nil && imageTask.aspectRatio != nil {
			handler(imageTask)
		}
	}
}
