//
//  ImageGalleryTableViewCell.swift
//  Image Gallery
//
//  Created by Peter Wu on 8/2/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryTableViewCell: UITableViewCell, UITextFieldDelegate {

	@IBOutlet weak var galleryNameTextField: UITextField! {
		didSet {
			galleryNameTextField.delegate = self
			galleryNameTextField.isEnabled = false

		}
	}
	
	var resignHandler: (() -> Void)?
	
	override func awakeFromNib() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(editGalleryName(_:)))
		tap.numberOfTapsRequired = 2
		addGestureRecognizer(tap)
	}
	
	@objc private func editGalleryName(_ tapGestureRecognizer: UITapGestureRecognizer) {
		// deselect cells
		self.setSelected(false, animated: true)
		galleryNameTextField.isEnabled = true
		galleryNameTextField.becomeFirstResponder()
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		resignHandler?()
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		textField.isEnabled = false
		return true
	}

}
