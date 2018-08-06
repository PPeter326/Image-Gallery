//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/22/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    
    // MARK: - Model
    var imageGallery = ImageGallery()
    
    // MARK: - Navigation item configuration
    
//    let trashCanButton: UIButton = {
//        let button = UIButton()
//        button.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
//        button.setBackgroundImage(UIImage(named: "trashcan2"), for: .normal)
//        return button
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The navigation bar button provides the same functionality as swipe left to reveal master list of image galleries
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.title = imageGallery.galleryName
        
//        let drop = UIDropInteraction(delegate: self)
//        trashCanButton.addInteraction(drop)
//        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: trashCanButton)
    }
    
    var dragSession: UIDragSession?
    
    @IBAction func springLoaded(_ sender: UIBarButtonItem) {
        
        // look for the item from drag session
        if let session = dragSession {
            if (session.localContext as? UICollectionView) == imageGalleryCollectionView {
				if !imageGalleryCollectionView.hasActiveDrag {
					dragSession = nil
				} else {
					let dragItems = session.items
					for item in dragItems {
						guard let imageTask = item.localObject as? ImageTask else { return }
						guard let index = imageGallery.imageTasks.index(of: imageTask) else { return }
						
						imageGalleryCollectionView.performBatchUpdates({
							imageGallery.imageTasks.remove(at: index)
							imageGalleryCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
						})
					}
					// cancel drag session
					dragSession = nil
				}
            }
            
        }
        
    }
    
	
    // MARK: - COLLECTION VIEW
    // MARK: Outlet
    @IBOutlet weak var imageGalleryCollectionView: UICollectionView! {
        didSet {
            imageGalleryCollectionView.dropDelegate = self
            imageGalleryCollectionView.dragDelegate = self
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
            imageGalleryCollectionView.addGestureRecognizer(pinch)
        }
    }
    
    // MARK: View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGallery.imageTasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.spinner.isHidden = false
            let imageTask = imageGallery.imageTasks[indexPath.item]
			fetchImage(url: imageTask.url!) { (image) in
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
	
	private  func fetchImage(url: URL ,completion: @escaping (UIImage?) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let data = try? Data(contentsOf: url.imageURL)
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
        // save reference to drag session for drag and drop to trashcan barbuttonitem
        dragSession = session
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
				let taskHandler = TaskHandler { imageTask in
					// weak reference to view controller because user may switch to a different document before image is loaded
					placeholderContext.commitInsertion(dataSourceUpdates: { [weak self] indexPath in
						self?.imageGallery.imageTasks.insert(imageTask, at: indexPath.item)
					})
				}
                let imageTask = ImageTask()
                
                // load URL and image asynchronously, then process handler
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    // receive imageURL data, and update data source while remove placeholder in main thread
                    DispatchQueue.main.async {
                        if let imageURL = provider as? URL {
                            imageTask.url = imageURL
                            taskHandler.process(imageTask: imageTask)
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            let aspectRatio = AspectRatio.calcAspectRatio(size: image.size)
                            imageTask.aspectRatio = aspectRatio
                            taskHandler.process(imageTask: imageTask)
                        }
                    }
                }
                
            }
        }
    }
    
    // MARK: - Gesture
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
