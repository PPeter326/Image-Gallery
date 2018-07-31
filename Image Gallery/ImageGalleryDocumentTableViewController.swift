//
//  ImageGalleryDocumentTableViewController.swift
//  Image Gallery
//
//  Created by Peter Wu on 7/30/18.
//  Copyright © 2018 Peter Wu. All rights reserved.
//

import UIKit

class ImageGalleryDocumentTableViewController: UITableViewController {

	// MARK: data
	var imageGalleries: [ImageGallery] = []
	var recentlyDeletedImageGalleries: [ImageGallery] = []
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if splitViewController?.preferredDisplayMode != .primaryOverlay {
			splitViewController?.preferredDisplayMode = .primaryOverlay
		}
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
		switch indexPath.section {
		case GallerySection.created:
			cell.textLabel?.text = imageGalleries[indexPath.row].galleryName
		case GallerySection.recentlyDeleted:
			cell.textLabel?.text = recentlyDeletedImageGalleries[indexPath.row].galleryName
		default: break
		}
        return cell
    }
	
	@IBAction func addImageGallery(_ sender: UIBarButtonItem) {
		let galleryNames = imageGalleries.map { $0.galleryName }
		imageGalleries.append(ImageGallery(galleryName: "Gallery".madeUnique(withRespectTo: galleryNames)))
		tableView.reloadData()
	}
	
	// MARK: - Table view selection
	
	
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
	If user swipe to delete an image gallery in the "created" (there's no title) section, the gallery object will be moved to the recently deleted section
	If user swipe to delete an image gallery from the recently deleted section, the gallery object will be permanently removed
	*/
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			switch indexPath.section {
			case GallerySection.created:
				tableView.performBatchUpdates({
					let gallery = imageGalleries.remove(at: indexPath.row)
					tableView.deleteRows(at: [indexPath], with: .fade)
					recentlyDeletedImageGalleries.append(gallery)
					if tableView.numberOfSections < 2 {
						tableView.insertSections(IndexSet([1]), with: .automatic)
					}
					tableView.insertRows(at: [IndexPath(row: recentlyDeletedImageGalleries.index(of: gallery)!, section: 1)], with: .automatic)
				})
			case GallerySection.recentlyDeleted:
				tableView.performBatchUpdates({
					recentlyDeletedImageGalleries.remove(at: indexPath.row)
					tableView.deleteRows(at: [indexPath], with: .fade)
					if recentlyDeletedImageGalleries.isEmpty {
						tableView.deleteSections(IndexSet([1]), with: .automatic)
					}
				})
			default: break
			}
		}
	}
	

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		guard sender is UITableViewCell else { return }
		guard segue.identifier == "ChooseGallery" else { return }

		if let indexPath = tableView.indexPathForSelectedRow {
			if let imageGalleryVC = segue.destination as? ImageGalleryViewController {
				imageGalleryVC.imageGallery = imageGalleries[indexPath.row]
			}
		}
    }
	

}
