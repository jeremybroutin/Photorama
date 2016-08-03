//
//  Photo.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/11/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
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
		remoteURL = NSURL()
		photoKey = NSUUID().UUIDString // custom subclass
		dateTaken = NSDate()
		viewsCount = 1
	}

}
