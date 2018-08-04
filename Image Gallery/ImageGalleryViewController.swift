//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/22/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate, UICollectionViewDragDelegate {
	
	// MARK: - COLLECTION VIEW

    @IBOutlet weak var imageGalleryCollectionView: UICollectionView! {
        didSet {
            imageGalleryCollectionView.dropDelegate = self
			imageGalleryCollectionView.dragDelegate = self
			let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
			imageGalleryCollectionView.addGestureRecognizer(pinch)
        }
    }
	
	// MARK: Data
	var imageGallery = ImageGallery()
	
	
	// MARK: View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGallery.imageTasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
		if let imageCell = cell as? ImageCollectionViewCell {
			imageCell.spinner.isHidden = false
			let imageTask = imageGallery.imageTasks[indexPath.item]
			imageTask.fetchImage { (image) in
				if let image = image {
					imageCell.imageView.image = image
				} else {
					// If there's no image loaded, show image with frown face
					imageCell.imageView.image = UIImage(named: "FrownFace")
				}
				// spinner hides automatically when it stops animating
				imageCell.spinner.stopAnimating()
			}
        }
        return cell
    }
	
	// MARK: Layout
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let cellWidth = view.frame.width.zoomedBy(zoomFactor)
		let aspectRatio = imageGallery.imageTasks[indexPath.item].aspectRatio ?? 1.0
		let cellHeight = cellWidth / aspectRatio
		return CGSize(width: cellWidth, height: cellHeight)
	}
	
	private var zoomFactor: CGFloat = 0.2 {
		didSet {
			// collectionView to layout cells again when zoom factor changes (which changes cell width)
			imageGalleryCollectionView.collectionViewLayout.invalidateLayout()
		}
	}
	
	private struct AspectRatio {
		static let widthToViewRatio: CGFloat = 0.2
		static func calcAspectRatio(size: CGSize) -> CGFloat {
			let width = size.width
			let height = size.height
			let aspectRatio = width / height
			return aspectRatio
		}
	}
	
	// MARK: Drag
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		// Provide local context to drag session, so that it'll be easy to distinguish in-app vs external drag
		session.localContext = collectionView
		return dragItems(at: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		return dragItems(at: indexPath)
	}
	
	private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
		let imageTask = imageGallery.imageTasks[indexPath.item]
		// The drag item is created from URL only, but it carries the whole imageTask in localObject which will allow rearranging items within the drag and drop view
		if let url = imageTask.url {
			let urlProvider = url as NSURL
			let urlItemProvider = NSItemProvider(object: urlProvider)
			let dragItem = UIDragItem(itemProvider: urlItemProvider)
			dragItem.localObject = imageTask
			return [dragItem]
		} else {
			return []
		}
	}
	
    // MARK: Drop
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        // The drop accepts NSURL only if it's within collection view (saved by local context).  External data from outside of the app must have both URL and image to be accepted.
		var canHandle: Bool
		if (session.localDragSession?.localContext as? UICollectionView) == collectionView {
			canHandle = session.canLoadObjects(ofClass: NSURL.self)
		} else {
			canHandle = session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
		}
        return canHandle
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        // Could be called many, many times.  Return quickly!
		let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
		return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		for item in coordinator.items {
			if item.isLocal {
				
				guard let sourceIndexPath = item.sourceIndexPath, let destinationIndexPath = coordinator.destinationIndexPath, let imageTask = item.dragItem.localObject as? ImageTask else { return }
				imageGalleryCollectionView.performBatchUpdates({
					self.imageGallery.imageTasks.remove(at: sourceIndexPath.item)
					self.imageGallery.imageTasks.insert(imageTask, at: destinationIndexPath.item)
					imageGalleryCollectionView.deleteItems(at: [sourceIndexPath])
					imageGalleryCollectionView.insertItems(at: [destinationIndexPath])
				})
				coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
				
			} else {
				
				guard item.dragItem.itemProvider.canLoadObject(ofClass: NSURL.self) && item.dragItem.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
				let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
				
				// Use placeholder cell while waiting for image and url to load.  The image task handler will replace placeholder cell with final content when both image and url are loaded.
				let placeHolder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell")
				let placeholderContext = coordinator.drop(item.dragItem, to: placeHolder)
				let imageTask = ImageTask { imageTask in
					// weak reference to view controller because user may switch to a different document before image is loaded
					placeholderContext.commitInsertion(dataSourceUpdates: { [weak self] indexPath in
						self?.imageGallery.imageTasks.insert(imageTask, at: indexPath.item)
					})
				}
				
				// load URL and image asynchronously, then process handler
				item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
					// receive imageURL data, and update data source while remove placeholder in main thread
					DispatchQueue.main.async {
						if let imageURL = provider as? URL {
							imageTask.url = imageURL
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
    
    // MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowImage" {
			if let imageVC = segue.destination as? ImageViewController {
				if let imageCell = sender as? ImageCollectionViewCell, let indexPath = imageGalleryCollectionView.indexPath(for: imageCell) {
					let imageTask = imageGallery.imageTasks[indexPath.item]
					let imageURL = imageTask.url
					imageVC.url = imageURL
				}
			}
		}
	}

}
