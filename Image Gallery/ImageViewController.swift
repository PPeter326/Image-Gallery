//
//  ImageViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 8/3/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

	@IBOutlet weak var spinner: UIActivityIndicatorView!
	
	var url: URL! {
		didSet {
			guard let imageURL = url?.imageURL else { return }
			DispatchQueue.global(qos: .userInitiated).async { [weak self] in
				let data = try? Data(contentsOf: imageURL)
				if let imageData = data {
					DispatchQueue.main.async {
						let image = UIImage(data: imageData)
						self?.imageView = UIImageView(image: image)
					}
				}
			}
		}
	}
	
	var imageView: UIImageView! {
		didSet {
			scrollView?.addSubview(imageView)
			scrollView?.contentSize = imageView.frame.size
			spinner.stopAnimating()
		}
	}
	
	@IBOutlet weak var scrollView: UIScrollView! {
		didSet {
			scrollView.delegate = self
			scrollView.minimumZoomScale = 0.2
			scrollView.maximumZoomScale = 5.0
		}
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		if let imageView = self.imageView {
			return imageView
		} else {
			return nil
		}
	}
	
	
	

}
