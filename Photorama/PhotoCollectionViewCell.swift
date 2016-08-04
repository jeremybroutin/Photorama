//
//  PhotoCollectionViewCell.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/3/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var spinner: UIActivityIndicatorView!
	
	// Reset each cell to the spinning state when the cell is first created and getting reused
	override func awakeFromNib() {
		super.awakeFromNib()
		
		updateWithImage(nil)
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		updateWithImage(nil)
	}
	
	// Helper method to only spin the activity indicator when the cell is not displaying an image
	func updateWithImage(image: UIImage?){
		if let imageToDisplay = image {
			spinner.stopAnimating()
			imageView.image = imageToDisplay
		}
		else {
			spinner.startAnimating()
			imageView.image = nil
		}
	}
	
}
