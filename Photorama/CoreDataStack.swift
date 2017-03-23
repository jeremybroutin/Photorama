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
	
	//MARK: - NSManagedObjectModel
	
	// Property to read in the model file from the main bundle
	fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = Bundle.main.url(forResource: self.managedObjectModelName, withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	// Note: lazily loading allows the property initialization to be deferred until it is actually needed
	
	
	//MARK: - NSPersistentStoreCoordinator
	
	// Prepare location for the store where data will be saved and loaded from
	fileprivate var applicationDocumentsDirectory: URL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls.first!
	}()
	
	// Create coordinator and add the specific store which needs to know its type (SQLite) and its location
	fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let pathComponent = "\(self.managedObjectModelName).sqlite"
		let url = self.applicationDocumentsDirectory.appendingPathComponent(pathComponent)
		let store = try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
		return coordinator
	}()
	
	
	// MARK: - NSmanagedObjectContext
	
	// The context is the portal through which you interact with your entities.
	// It is associated with a specific persistent core coordinator.
	
	// Hold an instance of managed object context (moc)
	lazy var mainQueueContext: NSManagedObjectContext = {
		let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		moc.persistentStoreCoordinator = self.persistentStoreCoordinator
		moc.name = "Main Queue Context (UI Context)"
		return moc
	}()
	
	lazy var privateQueueContext: NSManagedObjectContext = {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		// An NSManagedObjectContext can either be associated with a NSPersistentStoreCoordinator or with a 
		// parent NSManagedObjectContext
		moc.parent = self.mainQueueContext
		moc.name = "Primary Private Queue Context"
		return moc
	}()
	
	
	required init(modelName: String){
		managedObjectModelName = modelName
	}
	
	// The Model file is where you define the entitities for you application with their properties
	// and is an instance of NSManagedObjectModel
	
	// Save changes to the context after Photo entities have been inserted into the context
	func saveChanges() throws {
		var error: Error?
		
		
		privateQueueContext.performAndWait { () -> Void in
			if self.privateQueueContext.hasChanges {
				do {
					try self.privateQueueContext.save()
				}
				catch let saveError {
					error = saveError
				}
			}
		}
		if let error = error {
			throw error
		}
		
		mainQueueContext.performAndWait() {
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
