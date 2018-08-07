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
		if let imageGalleriesData = defaults.object(forKey: key) as? [Data] {
			for data in imageGalleriesData {
				if let imageGallery = try? JSONDecoder().decode(ImageGallery.self, from: data) {
					imageGalleries.append(imageGallery)
				}
			}
		}
		return imageGalleries
	}
	
	private func writeImageGalleriesToDefaults(galleryName: GalleryName) {
		var imageGalleriesData = [Data]()
		switch galleryName {
		case .created:
			for imageGallery in imageGalleries {
				if let data = try? JSONEncoder().encode(imageGallery) {
					imageGalleriesData.append(data)
				}
			}
			defaults.setValue(imageGalleriesData, forKey: DefaultsKey.imageGalleriesData)
		case .recentlyDeleted:
			for recentlyDeleteimageGallery in recentlyDeletedImageGalleries {
				if let data = try? JSONEncoder().encode(recentlyDeleteimageGallery) {
					imageGalleriesData.append(data)
				}
			}
			defaults.setValue(imageGalleriesData, forKey: DefaultsKey.recentlyDeletedImageGalleriesData)
		}
		if !defaults.synchronize() {
			print("failed to synchronize")
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
					}
				}
			case GallerySection.recentlyDeleted:
				imageGalleryTableViewCell.galleryNameTextField.text = recentlyDeletedImageGalleries[indexPath.row].galleryName
				imageGalleryTableViewCell.resignHandler = { [weak self, unowned imageGalleryTableViewCell] in
					if let updatedName = imageGalleryTableViewCell.galleryNameTextField.text {
						self?.recentlyDeletedImageGalleries[indexPath.row].galleryName = updatedName
					}
				}
			default: break
			}
		}
        return cell
    }
	
	@IBAction func addImageGallery(_ sender: UIBarButtonItem) {
		let galleryNames = imageGalleries.map { $0.galleryName }
		imageGalleries.append(ImageGallery(galleryName: "Gallery".madeUnique(withRespectTo: galleryNames)))
		tableView.reloadData()
		writeImageGalleriesToDefaults(galleryName: .created)
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
		writeImageGalleriesToDefaults(galleryName: .created)
		writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
	}
	
	private func permanentDeleteImageGallery(at indexPath: IndexPath) {
		recentlyDeletedImageGalleries.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .fade)
		if recentlyDeletedImageGalleries.isEmpty {
			tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
		}
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
		tableView.insertRows(at: [IndexPath(row: self.imageGalleries.index(of: gallery)!, section: GallerySection.created)], with: .automatic)
		writeImageGalleriesToDefaults(galleryName: .created)
		writeImageGalleriesToDefaults(galleryName: .recentlyDeleted)
	}
	
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		guard sender is UITableViewCell else { return }
		guard segue.identifier == "ChooseGallery" else { return }
		
		if let imageGalleryVC = segue.destination.contentVC as? ImageGalleryViewController {
			if let indexPath = tableView.indexPathForSelectedRow, indexPath.section == GallerySection.created {
				imageGalleryVC.imageGallery = imageGalleries[indexPath.row]
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


