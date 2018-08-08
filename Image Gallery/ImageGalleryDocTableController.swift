//
//  ImageGalleryDocumentTableViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryDocTableController: UITableViewController {

	
	// MARK: data
	private let defaults = UserDefaults.standard
	lazy private var imageGalleries: [ImageGallery] = readImageGalleriesFromDefaults(galleryName: .created)
	lazy private var recentlyDeletedImageGalleries: [ImageGallery] = readImageGalleriesFromDefaults(galleryName: .recentlyDeleted)
	
	private func readImageGalleriesFromDefaults(galleryName: GalleryName) -> [ImageGallery] {
		var imageGalleries = [ImageGallery]()
		var key: String
		switch galleryName {
		case .created:
			key = DefaultsKey.imageGalleriesData
		case .recentlyDeleted:
			key = DefaultsKey.recentlyDeletedImageGalleriesData
		}
		guard let imageGalleryHashValues = defaults.object(forKey: key) as? [Int] else { return imageGalleries }
		for imageGalleryHashValue in imageGalleryHashValues {
			if let imageGalleryData = defaults.object(forKey: String(imageGalleryHashValue)) as? Data, let imageGallery = try? JSONDecoder().decode(ImageGallery.self, from: imageGalleryData)  {
				imageGalleries.append(imageGallery)
			}
		}
		imageGalleries.sort { $0.hashValue < $1.hashValue }
		return imageGalleries
	}
	
	private func writeImageGalleriesToDefaults(galleryName: GalleryName) {
		var imageGalleriesHashValues = [Int]()
		var defaultsKey: String
		switch galleryName {
		case .created:
			// create a dictionary of gallery names and image gallery object
			imageGalleries.forEach { imageGallery in
				let hashValue = imageGallery.hashValue
				if let imageData = try? JSONEncoder().encode(imageGallery) {
					defaults.setValue(imageData, forKey: String(hashValue))
					imageGalleriesHashValues.append(hashValue)
				}
			}
			defaultsKey = DefaultsKey.imageGalleriesData
		case .recentlyDeleted:
			recentlyDeletedImageGalleries.forEach { imageGallery in
				let hashValue = imageGallery.hashValue
				if let imageData = try? JSONEncoder().encode(imageGallery) {
					defaults.setValue(imageData, forKey: String(hashValue))
					imageGalleriesHashValues.append(hashValue)
				}
			}
			defaultsKey = DefaultsKey.recentlyDeletedImageGalleriesData
		}
		defaults.setValue(imageGalleriesHashValues, forKey: defaultsKey)
	}
	
	weak var timer: Timer?
	var selectedRowIndexPath: IndexPath?
	private func deselectRow() {
		selectedRowIndexPath = nil
		performSegue(withIdentifier: SegueName.chooseGallery, sender: nil)

	}
	private func showSelectedImageGallery(at indexPath: IndexPath) {
		timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] (timer) in
			self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			// get the cell, then perform segue using the cell
			if let cell = self?.tableView.cellForRow(at: indexPath) as? ImageGalleryTableViewCell {
				self?.performSegue(withIdentifier: SegueName.chooseGallery, sender: cell)
			}
		})
	}
	
	private func selectFirstImageGallery() {
		let indexPath = IndexPath(row: imageGalleries.startIndex, section: GallerySection.created)
		timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] (timer) in
			self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			// get the cell, then perform segue using the cell
			if let cell = self?.tableView.cellForRow(at: indexPath) as? ImageGalleryTableViewCell {
				self?.performSegue(withIdentifier: SegueName.chooseGallery, sender: cell)
			}
		})
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if !imageGalleries.isEmpty {
			if selectedRowIndexPath == nil {
				selectFirstImageGallery()
			} else {
				showSelectedImageGallery(at: selectedRowIndexPath!)
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
			self.selectedRowIndexPath = selectedRowIndexPath
		}
		
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if splitViewController?.preferredDisplayMode != .primaryOverlay {
			splitViewController?.preferredDisplayMode = .primaryOverlay
		}
	}
	
	private struct DefaultsKey {
		static let imageGalleriesData: String = "Image Galleries Data"
		static let recentlyDeletedImageGalleriesData: String = "Recently Deleted Image Galleries Data"
	}
	
	private enum GalleryName {
		case created
		case recentlyDeleted
	}

    // MARK: - Table view data source
	private struct GallerySection {
		static let created: Int = 0
		static let recentlyDeleted: Int = 1
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
		return recentlyDeletedImageGalleries.isEmpty ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case GallerySection.created: return imageGalleries.count
		case GallerySection.recentlyDeleted: return recentlyDeletedImageGalleries.count
		default: return 0
		}
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == GallerySection.recentlyDeleted ? "Recently Deleted" : nil
	}
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
		if let imageGalleryTableViewCell = cell as? ImageGalleryTableViewCell {
			switch indexPath.section {
			case GallerySection.created:
				imageGalleryTableViewCell.galleryNameTextField.text = imageGalleries[indexPath.row].galleryName
				imageGalleryTableViewCell.resignHandler = { [weak self, unowned imageGalleryTableViewCell] in
					if let updatedName = imageGalleryTableViewCell.galleryNameTextField.text {
						self?.imageGalleries[indexPath.row].galleryName = updatedName
						self?.writeImageGalleriesToDefaults(galleryName: .created)
					}
				}
			case GallerySection.recentlyDeleted:
				imageGalleryTableViewCell.galleryNameTextField.text = recentlyDeletedImageGalleries[indexPath.row].galleryName
				imageGalleryTableViewCell.resignHandler = { [weak self, unowned imageGalleryTableViewCell] in
					if let updatedName = imageGalleryTableViewCell.galleryNameTextField.text {
						self?.recentlyDeletedImageGalleries[indexPath.row].galleryName = updatedName
						self?.writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
					}
				}
			default: break
			}
		}
        return cell
    }
	
	fileprivate func createNewGallery() -> ImageGallery{
		let galleryNames = imageGalleries.map { $0.galleryName }
		let newGallery = ImageGallery(galleryName: "Gallery".madeUnique(withRespectTo: galleryNames))
		imageGalleries.append(newGallery)
		return newGallery
	}
	
	@IBAction func addImageGallery(_ sender: UIBarButtonItem) {
		let newGallery = createNewGallery()
		tableView.reloadData()
		writeImageGalleriesToDefaults(galleryName: .created)
		guard let index = imageGalleries.index(of: newGallery) else { return }
		let indexPath = IndexPath(row: index, section: GallerySection.created)
		showSelectedImageGallery(at: indexPath)
	}
	
	// MARK: - Table view selection
	
    /*
	If user swipe to delete an image gallery in the "created" (there's no title) section, the gallery object will be moved to the recently deleted section
	If user swipe to delete an image gallery from the recently deleted section, the gallery object will be permanently removed
	*/
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			var imageGalleryUpdate: ((IndexPath) -> Void)?
			
			switch indexPath.section {
			case GallerySection.created:
				imageGalleryUpdate = deleteImageGallery
			case GallerySection.recentlyDeleted:
				imageGalleryUpdate = permanentDeleteImageGallery
			default: break
			}
			tableView.performBatchUpdates({
				imageGalleryUpdate?(indexPath)
			})
		}
	}
	
	override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		if indexPath.section == GallerySection.recentlyDeleted {
			let undeleteSwipeActionConfiguration = UISwipeActionsConfiguration(actions: [makeUndeleteCellAction(at: indexPath)])
			return undeleteSwipeActionConfiguration
		} else {
			return nil
		}
	}
	
	private func makeUndeleteCellAction(at indexPath: IndexPath) -> UIContextualAction {
		let action = UIContextualAction(style: .normal, title: "Undelete") { (action, view, completed) in
			self.tableView.performBatchUpdates({ [unowned self] in
				self.undeleteImageGallery(at: indexPath)
				})
			completed(true)
		}
		action.backgroundColor = UIColor.blue
		return action
	}
	
	private func deleteImageGallery(at indexPath: IndexPath) {
		let gallery = imageGalleries.remove(at: indexPath.row)
		recentlyDeletedImageGalleries.append(gallery)
		recentlyDeletedImageGalleries.sort() { $1.hashValue > $0.hashValue }
		tableView.deleteRows(at: [indexPath], with: .fade)
		if tableView.numberOfSections < 2 {
			tableView.insertSections(IndexSet(integer: 1), with: .automatic)
		}
		tableView.insertRows(at: [IndexPath(row: recentlyDeletedImageGalleries.index(of: gallery)!, section: GallerySection.recentlyDeleted)], with: UITableViewRowAnimation.automatic)
		deselectRow()
		writeImageGalleriesToDefaults(galleryName: .created)
		writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
	}
	
	private func permanentDeleteImageGallery(at indexPath: IndexPath) {
		recentlyDeletedImageGalleries.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .fade)
		if recentlyDeletedImageGalleries.isEmpty {
			tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
		}
		selectedRowIndexPath = nil
		writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
	}
	private func undeleteImageGallery(at indexPath: IndexPath) {
		// update model and tableview
		let gallery = self.recentlyDeletedImageGalleries.remove(at: indexPath.row)
		self.imageGalleries.append(gallery)
		self.imageGalleries.sort(){ $0.hashValue < $1.hashValue }
		tableView.deleteRows(at: [indexPath], with: .fade)
		if self.recentlyDeletedImageGalleries.isEmpty { tableView.deleteSections(IndexSet(integer: 1), with: .fade)}
		if tableView.numberOfSections < 2 {
			tableView.insertSections(IndexSet(integer: 1), with: .automatic)
		}
		let newIndexPath = IndexPath(row: self.imageGalleries.index(of: gallery)!, section: GallerySection.created)
		tableView.insertRows(at: [newIndexPath], with: .automatic)
		deselectRow()
		
		writeImageGalleriesToDefaults(galleryName: .created)
		writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
	}
	
    // MARK: - Navigation

	private struct SegueName {
		static let chooseGallery: String = "ChooseGallery"
	}
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		guard segue.identifier == SegueName.chooseGallery else { return }
		
		if let imageGalleryVC = segue.destination.contentVC as? ImageGalleryViewController {
			if let indexPath = tableView.indexPathForSelectedRow, indexPath.section == GallerySection.created {
				imageGalleryVC.imageGallery = imageGalleries[indexPath.row]
			} else {
				imageGalleryVC.imageGallery = nil
			}
		}
    }
	

}

extension UIViewController {
	var contentVC: UIViewController{
		if let navCon = self as? UINavigationController, let visibleVC = navCon.visibleViewController {
			return visibleVC
		} else {
			return self
		}
	}
}


