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
//	override func viewWillLayoutSubviews() {
//		super.viewWillLayoutSubviews()
//		if splitViewController?.preferredDisplayMode != .primaryOverlay {
//			splitViewController?.preferredDisplayMode = .primaryOverlay
//		}
//	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageGalleries.count
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)

        // Configure the cell...
		cell.textLabel?.text = imageGalleries[indexPath.row].galleryName

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
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
