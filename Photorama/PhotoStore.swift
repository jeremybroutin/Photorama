//
//  PhotoStore.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/2/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import CoreData

class PhotoStore {
	
	enum ImageResult{
		case success(UIImage)
		case failure(Error)
	}
	
	enum PhotoError: Error {
		case imageCreationError
	}
    
    // hold an instance of NSURLSession
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
	
	// hold an instance of CoreDataStack
	let coreDataStack = CoreDataStack(modelName: "Photorama")
	
	// property for image store
	let imageStore = ImageStore()
    
	// Note: The fetch method signature takes in a completion closure that will be called once the web service request is completed
	// Fetching web data is asynchronous, so the method cannot directly return an instance of PhotosResult
	// Instead the caller of this method will siply a completion closure for the PhotoStore to call once the request is completed
	
	func fetchPhotos(_ method: Method, keyword: String?, completion: @escaping (PhotosResult) -> Void) {
		
		var url: URL!
		
		switch method {
		case .RecentPhotos:
			url = FlickrAPI.recentPhotosURL()
		case .Search:
			if let keyword = keyword {
				url = FlickrAPI.searchPhotosURL(keyword)
			}
		}
		
		let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            
            // completion closure to call when the request finishes
            var result = self.processRecentPhotosRequest(data: data, error: error)
			
			if case let .success(photos) = result {
				let privateQueueContext = self.coreDataStack.privateQueueContext
				privateQueueContext.performAndWait({
					try! privateQueueContext.obtainPermanentIDs(for: photos)
				})
				let objectIDs = photos.map{ $0.objectID }
				let predicate = NSPredicate(format: "self IN %@", objectIDs)
				let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
				
				do{
					try self.coreDataStack.saveChanges()
					
					let mainQueuePhotos = try self.fetchMainQueuePhotos(predicate: predicate, sortDescriptors: [sortByDateTaken])
					result = .success(mainQueuePhotos)
				}
				catch let error {
					result = .failure(error)
				}
			}
			
			// print response status code and headerFields for debugging web service calls
			let httpResponse = response as! HTTPURLResponse
			//print("\(httpResponse.statusCode), \(httpResponse.allHeaderFields)")
			print("\(httpResponse.statusCode)")
			
			completion(result)
        })
        
        // tasks are always created in a suspended state so we need to call resume to start the web service
        task.resume()
    }
	
	func processRecentPhotosRequest(data: Data? , error: Error?)-> PhotosResult {
		guard let jsonData = data else {
			return .failure(error!)
		}
		
		// Pass the mainQueuContext to the FlickrAPI struct once the web service request successfully completes
		return FlickrAPI.photosFromJSONData(jsonData, inContext: self.coreDataStack.privateQueueContext)
	}
	
	// Download the image data from the Photo remoteURL
	func fetchImageForPhoto(_ photo: Photo, completion: @escaping (ImageResult) -> Void) {
		
		// If the image already exists, it should not be downloaded again and instead give the saved image in Core data
		let photoKey = photo.photoKey
		if let image = imageStore.imageForKey(photoKey) {
			photo.image = image
			completion(.success(image))
			return
		}
		
		// Otherwise, go ahead, download it and save it to Core data
		let photoURL = photo.remoteURL
		let request = URLRequest(url: photoURL as URL)
		
		let task = session.dataTask(with: request, completionHandler: {
			(data, response, error) in
			
			let result = self.processImageRequest(data: data, error: error as NSError?)
			
			// Can use an if case statement to check wether result has a value of .Success
			// Similar to a switch case with a break under the .Failure case
			if case let .success(image) = result {
				photo.image = image
				self.imageStore.setImage(image, forKey: photoKey)
			}
			
			completion(result)
		}) 
		
		task.resume()
	}
	
	// Process the data fromn the web service request into an image, if possible
	func processImageRequest(data: Data?, error: NSError?) -> ImageResult {
		
		guard let
			imageData = data,
			let image = UIImage(data:imageData) else {
			
			// Couldn't create an image
			if data == nil {
				return .failure(error!)
			}
			else {
				return .failure(PhotoError.imageCreationError)
			}
		}
		
		return .success(image)
	}
	
	// Fetch Photos instances from the main queue context
	func fetchMainQueuePhotos(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Photo] {
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
		fetchRequest.sortDescriptors = sortDescriptors
		fetchRequest.predicate = predicate
		
		let mainQueueContext = self.coreDataStack.mainQueueContext
		var mainQueuePhotos: [Photo]?
		var fetchRequestError: Error?
		mainQueueContext.performAndWait() {
			do {
				mainQueuePhotos = try mainQueueContext.fetch(fetchRequest) as? [Photo]
			}
			catch let error {
				fetchRequestError = error
			}
		}
		
		guard let photos = mainQueuePhotos else {
			throw fetchRequestError!
		}
		
		return photos
	}
	
	// Fetch Tags from main queue
	func fetchMainQueueTags(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [NSManagedObject] {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = sortDescriptors
		
		let mainQueueContext = self.coreDataStack.mainQueueContext
		var mainQueueTags: [NSManagedObject]?
		var fetchRequestError: Error?
		
		mainQueueContext.performAndWait({
			do {
				mainQueueTags = try mainQueueContext.fetch(fetchRequest) as? [NSManagedObject]
			}
			catch let error {
				fetchRequestError = error
			}
		})
		
		guard let tags = mainQueueTags else { throw fetchRequestError! }
		
		return tags
		
	}
}
