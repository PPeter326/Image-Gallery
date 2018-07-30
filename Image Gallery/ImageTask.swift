//
//  Image.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/27/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import Foundation
import UIKit

class ImageTask {
	
	var url: URL?
	var aspectRatio: CGFloat?
	
	private var handler: (ImageTask) -> Void
	
	init(handler: @escaping (ImageTask) -> Void) {
		self.handler = handler
	}
	
	func process() {
		if url != nil && aspectRatio != nil {
			handler(self)
		}
	}
	
	func fetchImage(completion: @escaping (UIImage?) -> Void) {
		guard let url = self.url?.imageURL else { return }
		DispatchQueue.global(qos: .userInitiated).async {
			let data = try? Data(contentsOf: url)
			if let imageData = data {
				DispatchQueue.main.async {
					let image = UIImage(data: imageData)
					completion(image)
				}
			} else {
				completion(nil)
			}
		}
	}
	
}
