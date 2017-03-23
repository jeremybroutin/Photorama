//
//  PhotoInfoViewController.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/9/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class PhotoInfoViewController: UIViewController {
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var isFavoriteButton: UIBarButtonItem!
	@IBOutlet var viewsCountButton: UIBarButtonItem!

	// The PhotosViewController will pass both the Photo and the PhotoStore
	// to this PhotoInfoViewController
	
	var photo: Photo!{
		didSet{
			navigationItem.title = photo.title
			
		}
	}
	var store: PhotoStore!
	
	// MARK: - App Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Customize navigation bar
		let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PhotoInfoViewController.sharePhoto(_:)))
		shareButton.isEnabled = false
		navigationItem.rightBarButtonItem = shareButton
		
		// Get the image from the selected photo
		store.fetchImageForPhoto(photo) { (result) in
			switch result {
			case let .success(image):
				OperationQueue.main.addOperation({
					self.imageView.image = image
					shareButton.isEnabled = true
				})
			case let .failure(error):
				print("Error fetching image for photo: \(error)")
				
			}
		}
		
		// Check if it's a favorite or not
		isFavoriteButton.tintColor = photo.isFavorite ? UIColor.red : UIColor.gray
		
		// Add view count data
		viewsCountButton.title = "Views: \(photo.viewsCount)"
	}
	
	// MARK: - Segue
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowTags"{
			let navController = segue.destination as! UINavigationController
			let tagController = navController.topViewController as! TagsViewController
			
			tagController.store = store
			tagController.photo = photo
		}
	}
	
	// MARK: - Helper functions
	
	func sharePhoto(_ sender:AnyObject){
		let activityVC = UIActivityViewController(activityItems: [photo.image!], applicationActivities: nil)
		activityVC.popoverPresentationController?.sourceView = sender as? UIView
		self.present(activityVC, animated: true, completion: nil)
	}
	
	@IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
		photo.isFavorite = !photo.isFavorite
		isFavoriteButton.tintColor = photo.isFavorite ? UIColor.red : UIColor.gray
		
		do {
			try store.coreDataStack.saveChanges()
		}
		catch let error {
			print("Core Data saved failed: \(error)")
		}
	}

}
