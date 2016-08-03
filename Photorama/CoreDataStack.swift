//
//  CoreDataStack.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/11/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
	
	let managedObjectModelName: String
	
	/********** MARK: - NSManagedObjectModel **********/
	
	// Property to read in the model file from the main bundle
	private lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = NSBundle.mainBundle().URLForResource(self.managedObjectModelName, withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()
	// Note: lazily loading allows the property initialization to be deferred until it is actually needed
	
	
	/********** MARK: - NSPersistentStoreCoordinator **********/
	
	// Prepare location for the store where data will be saved and loaded from
	private var applicationDocumentsDirectory: NSURL = {
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls.first!
	}()
	
	// Create coordinator and add the specific store which needs to know its type (SQLite) and its location
	private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let pathComponent = "\(self.managedObjectModelName).sqlite"
		let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(pathComponent)
		let store = try! coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
		return coordinator
	}()
	
	
	/********** MARK: - NSmanagedObjectContext **********/
	
	// The context is the portal through which you interact with your entities.
	// It is associated with a specific persistent core coordinator.
	
	// Hold an instance of managed object context (moc)
	lazy var mainQueueContext: NSManagedObjectContext = {
		let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		moc.persistentStoreCoordinator = self.persistentStoreCoordinator
		moc.name = "Main Queue Context (UI Context)"
		return moc
	}()
	
	
	required init(modelName: String){
		managedObjectModelName = modelName
	}
	
	// The Model file is where you define the entitities for you application with their properties
	// and is an instance of NSManagedObjectModel
	
	// Save changes to the context after Photo entities have been inserted into the context
	func saveChanges() throws {
		var error: ErrorType?
		mainQueueContext.performBlockAndWait() {
			if self.mainQueueContext.hasChanges {
				do {
					try self.mainQueueContext.save()
				}
				catch let saveError {
					error = saveError
				}
			}
		}
		if let error = error {
			throw error
		}
	}
}
