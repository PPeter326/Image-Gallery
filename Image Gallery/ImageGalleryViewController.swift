//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/22/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate {
    
    
    
    
    @IBOutlet weak var imageGalleryCollectionView: UICollectionView! {
        didSet {
            imageGalleryCollectionView.dropDelegate = self
			let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
			imageGalleryCollectionView.addGestureRecognizer(pinch)
        }
    }
    
    
    
    
    // MARK: - COLLECTION VIEW
	
	// MARK: Data
	private var imageTasks: [ImageTask] = [] {
		didSet {
			print("image tasks count: \(imageTasks.count)")
		}
	}
	
	// MARK: View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(#function)
        return imageTasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print(#function)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        if let imageCell = cell as? ImageCell {
            imageCell.spinner.isHidden = false
			let imageTask = imageTasks[indexPath.item]
			imageTask.fetchImage { (image) in
				if let image = image {
					imageCell.imageView.image = image
				} else {
					// If there's no image loaded, show image with frown face
					imageCell.imageView.image = UIImage(named: "FrownFace")
				}
				imageCell.spinner.stopAnimating()
			}
        }
        return cell
    }
	private struct AspectRatio {
		
		static let widthToViewRatio: CGFloat = 0.2
		
		static func calcAspectRatio(size: CGSize) -> CGFloat {
			let width = size.width
			let height = size.height
			let aspectRatio = height / width
			return aspectRatio
		}
	}
	// MARK: Layout
	
	var zoomFactor: CGFloat = 0.2 {
		didSet {
			// collectionView to layout cells again when zoom factor changes (which changes cell width)
			imageGalleryCollectionView.collectionViewLayout.invalidateLayout()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let cellWidth = view.frame.width * zoomFactor
		let cellHeight = (imageTasks[indexPath.item].aspectRatio ?? 1.0) * cellWidth
		return CGSize(width: cellWidth, height: cellHeight)
	}
	
    // MARK: Drop
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        print(#function)
        // can handle URL and image
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        print(#function)
        // Could be called many, many times.  Return quickly!
        return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }
    
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		print(#function)
		// all items are coming from outside of the app, so use itemprovider to load contents asynchronously
		for item in coordinator.items {
			if item.dragItem.itemProvider.canLoadObject(ofClass: NSURL.self) {
				let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
				// create placeholder
				let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
				let imageTask = ImageTask { imageTask in
					placeholderContext.commitInsertion(dataSourceUpdates: { indexPath in
						self.imageTasks.insert(imageTask, at: indexPath.item)
					})
				}
				
				// load URL and image asynchronously, then process handler
				item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in // asynchronously loading, need to perform UI update in main thread
					// receive imageURL data, and update data source while remove placeholder in main thread
					DispatchQueue.main.async {
						if let imageURL = provider as? URL {
							imageTask.source = imageURL
							imageTask.process()
						}
					}
				}
				item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
					DispatchQueue.main.async {
						if let image = provider as? UIImage {
							let aspectRatio = AspectRatio.calcAspectRatio(size: image.size)
							imageTask.aspectRatio = aspectRatio
							imageTask.process()
						}
					}
				}
			}
		}
	}
	// MARK: Gesture
	@objc func zoom(_ pinchGestureRecognizer: UIPinchGestureRecognizer) {
		switch pinchGestureRecognizer.state {
		case .changed: // changes the zoom factor by the scale
			zoomFactor *= pinchGestureRecognizer.scale
			pinchGestureRecognizer.scale = 1.0 // reset scale so that it's not cumulative
		default: return
		}
		
	}
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
