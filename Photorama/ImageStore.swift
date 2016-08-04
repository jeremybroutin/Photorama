//
//  ImageStore.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/13/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class ImageStore {
	let cache = NSCache()
	
	func setImage(image: UIImage, forKey key: String) {
		cache.setObject(image, forKey: key)
		
		// Create full URL for image
		let imageUrl = imageUrlForKey(key)
		
		// Turn image into JPEG data
		if let data = UIImageJPEGRepresentation(image, 0.5) {
			// Write it to full URL
			data.writeToURL(imageUrl, atomically: true)
		}
	}
	
	func imageForKey(key: String) -> UIImage? {
		if let existingImage = cache.objectForKey(key) as? UIImage {
			return existingImage
		}
		
		let imageURL = imageUrlForKey(key)
		guard let imagefromDisk = UIImage(contentsOfFile: imageURL.path!) else {
			return nil
		}
		
		cache.setObject(imagefromDisk, forKey: key)
		return imagefromDisk
	}
	
	func deleteImageForKey(key: String) {
		cache.removeObjectForKey(key)
		
		let imageURL = imageUrlForKey(key)
		do {
			try NSFileManager.defaultManager().removeItemAtURL(imageURL)
		} catch let deleteError {
			print("Error removing image from disk: \(deleteError)")
		}
	}
	
	func imageUrlForKey(key: String) -> NSURL {
		let documentsDirectories = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		let documentDirectory = documentsDirectories.first!
		
		return documentDirectory.URLByAppendingPathComponent(key)
	}
}
