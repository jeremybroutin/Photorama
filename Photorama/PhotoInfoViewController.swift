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
	
	/* MARK: - App Life Cycle */
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Customize navigation bar
		let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(PhotoInfoViewController.sharePhoto(_:)))
		shareButton.enabled = false
		navigationItem.rightBarButtonItem = shareButton
		
		// Get the image from the selected photo
		store.fetchImageForPhoto(photo) { (result) in
			switch result {
			case let .Success(image):
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.imageView.image = image
					shareButton.enabled = true
				})
			case let .Failure(error):
				print("Error fetching image for photo: \(error)")
				
			}
		}
		
		// Check if it's a favorite or not
		isFavoriteButton.tintColor = photo.isFavorite ? UIColor.redColor() : UIColor.grayColor()
		
		// Add view count data
		viewsCountButton.title = "Views: \(photo.viewsCount)"
	}
	
	/* MARK:- Helper functions */
	
	func sharePhoto(sender:AnyObject){
		let activityVC = UIActivityViewController(activityItems: [photo.image!], applicationActivities: nil)
		activityVC.popoverPresentationController?.sourceView = sender as? UIView
		self.presentViewController(activityVC, animated: true, completion: nil)
	}
	
	@IBAction func toggleFavorite(sender: UIBarButtonItem) {
		photo.isFavorite = !photo.isFavorite
		isFavoriteButton.tintColor = photo.isFavorite ? UIColor.redColor() : UIColor.grayColor()
		
		do {
			try store.coreDataStack.saveChanges()
		}
		catch let error {
			print("Core Data saved failed: \(error)")
		}
	}

}
