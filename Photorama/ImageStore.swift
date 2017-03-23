//
//  ImageStore.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/13/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class ImageStore {
	let cache = NSCache<AnyObject, AnyObject>()
	
	func setImage(_ image: UIImage, forKey key: String) {
		cache.setObject(image, forKey: key as AnyObject)
		
		// Create full URL for image
		let imageUrl = imageUrlForKey(key)
		
		// Turn image into JPEG data
		if let data = UIImageJPEGRepresentation(image, 0.5) {
			// Write it to full URL
			try? data.write(to: imageUrl, options: [.atomic])
		}
	}
	
	func imageForKey(_ key: String) -> UIImage? {
		if let existingImage = cache.object(forKey: key as AnyObject) as? UIImage {
			return existingImage
		}
		
		let imageURL = imageUrlForKey(key)
		guard let imagefromDisk = UIImage(contentsOfFile: imageURL.path) else {
			return nil
		}
		
		cache.setObject(imagefromDisk, forKey: key as AnyObject)
		return imagefromDisk
	}
	
	func deleteImageForKey(_ key: String) {
		cache.removeObject(forKey: key as AnyObject)
		
		let imageURL = imageUrlForKey(key)
		do {
			try FileManager.default.removeItem(at: imageURL)
		} catch let deleteError {
			print("Error removing image from disk: \(deleteError)")
		}
	}
	
	func imageUrlForKey(_ key: String) -> URL {
		let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentDirectory = documentsDirectories.first!
		
		return documentDirectory.appendingPathComponent(key)
	}
}
