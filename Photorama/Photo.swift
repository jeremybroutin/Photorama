//
//  Photo.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/11/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import Foundation
import CoreData


class Photo: NSManagedObject {

	// Insert code here to add functionality to your managed object subclass
	var image: UIImage?
	
	// When the web service request returnsm the photos will be added to the database,
	// When objects are added to the database they are svia the message awakeFromInsert()
	
	override func awakeFromInsert() {
		super.awakeFromInsert()
		
		// Give the properties their initial values
		title = ""
		photoID = ""
		remoteURL = NSURLComponents().url!
		photoKey = UUID().uuidString // custom subclass
		dateTaken = Date()
		viewsCount = NSNumber(value: 0 as Float)
		isFavorite = false
	}
	
	func addTagObject(_ tag: NSManagedObject){
		let currentTags = mutableSetValue(forKey: "tags")
		currentTags.add(tag)
	}
	
	func removeTagObject(_ tag:NSManagedObject){
		let currentTags = mutableSetValue(forKey: "tags")
		currentTags.remove(tag)
	}

}
