//
//  Photo+CoreDataProperties.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/13/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var dateTaken: NSDate
    @NSManaged var photoID: String
    @NSManaged var photoKey: String
    @NSManaged var remoteURL: NSURL
    @NSManaged var title: String
    @NSManaged var viewsCount: NSNumber
	@NSManaged var isFavorite: Bool
	@NSManaged var tags: Set<NSManagedObject>

}
