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
	
	// The PhotosViewController will pass both the Photo and the PhotoStore
	// to this PhotoInfoViewController
	
	var photo: Photo!{
		didSet{
			navigationItem.title = photo.title
		}
	}
	var store: PhotoStore!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		store.fetchImageForPhoto(photo) { (result) in
			switch result {
			case let .Success(image):
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.imageView.image = image
				})
			case let .Failure(error):
				print("Error fetching image for photo: \(error)")
				
			}
		}
	}
}
