//
//  TaskHandler.swift
//  Image Gallery
//
//  Created by Peter Wu on 8/6/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation
import UIKit

class TaskHandler {
	
	private var handler: (URL, CGFloat) -> Void
	
	init(handler: @escaping (URL, CGFloat) -> Void) {
		self.handler = handler
	}
	
    func process(image: (url: URL?, aspectRatio: CGFloat?)) {
		if image.url != nil && image.aspectRatio != nil {
            handler(image.url!, image.aspectRatio!)
		}
	}
}
