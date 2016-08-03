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
		case Success(UIImage)
		case Failure(ErrorType)
	}
	
	enum PhotoError: ErrorType {
		case ImageCreationError
	}
    
    // hold an instance of NSURLSession
    let session: NSURLSession = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: config)
    }()
	
	// hold an instance of CoreDataStack
	let coreDataStack = CoreDataStack(modelName: "Photorama")
	
	// property for image store
	let imageStore = ImageStore()
    
	// Note: The fetch method signature takes in a completion closure that will be called once the web service request is completed
	// Fetching web data is asynchronous, so the method cannot directly return an instance of PhotosResult
	// Instead the caller of this method will siply a completion closure for the PhotoStore to call once the request is completed
	
	func fetchPhotos(method: Method, keyword: String?, completion: (PhotosResult) -> Void) {
		
		var url = NSURL()
		
		switch method {
		case .RecentPhotos:
			url = FlickrAPI.recentPhotosURL()
		case .Search:
			if let keyword = keyword {
				url = FlickrAPI.searchPhotosURL(keyword)
			}
		}
		
		let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request){
            (data, response, error) -> Void in
            
            // completion closure to call when the request finishes
            var result = self.processRecentPhotosRequest(data: data, error: error)
			
			if case let .Success(photos) = result {
				let mainQueueContext = self.coreDataStack.mainQueueContext
				mainQueueContext.performBlockAndWait({
					try! mainQueueContext.obtainPermanentIDsForObjects(photos)
				})
				let objectIDs = photos.map{ $0.objectID }
				let predicate = NSPredicate(format: "self IN %@", objectIDs)
				let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
				
				do{
					try self.coreDataStack.saveChanges()
					
					let mainQueuePhotos = try self.fetchMainQueuePhotos(predicate: predicate, sortDescriptors: [sortByDateTaken])
					result = .Success(mainQueuePhotos)
				}
				catch let error {
					result = .Failure(error)
				}
			}
			
			// print response status code and headerFields for debugging web service calls
			let httpResponse = response as! NSHTTPURLResponse
			print("\(httpResponse.statusCode), \(httpResponse.allHeaderFields)")
			
			completion(result)
        }
        
        // tasks are always created in a suspended state so we need to call resume to start the web service
        task.resume()
    }
	
	func processRecentPhotosRequest(data data: NSData? , error: NSError?)-> PhotosResult {
		guard let jsonData = data else {
			return .Failure(error!)
		}
		
		// Pass the mainQueuContext to the FlickrAPI struct once the web service request successfully completes
		return FlickrAPI.photosFromJSONData(jsonData, inContext: self.coreDataStack.mainQueueContext)
	}
	
	// Download the image data from the Photo remoteURL
	func fetchImageForPhoto(photo: Photo, completion: (ImageResult) -> Void) {
		
		// If the image already exists, it should not be downloaded again and instead give the saved image in Core data
		let photoKey = photo.photoKey
		if let image = imageStore.imageForKey(photoKey) {
			photo.image = image
			completion(.Success(image))
			return
		}
		
		// Otherwise, go ahead, download it and save it to Core data
		let photoURL = photo.remoteURL
		let request = NSURLRequest(URL: photoURL)
		
		let task = session.dataTaskWithRequest(request) {
			(data, response, error) in
			
			let result = self.processImageRequest(data: data, error: error)
			
			// Can use an if case statement to check wether result has a value of .Success
			// Similar to a switch case with a break under the .Failure case
			if case let .Success(image) = result {
				photo.image = image
				self.imageStore.setImage(image, forKey: photoKey)
			}
			
			completion(result)
		}
		
		task.resume()
	}
	
	// Process the data fromn the web service request into an image, if possible
	func processImageRequest(data data: NSData?, error: NSError?) -> ImageResult {
		
		guard let
			imageData = data,
			image = UIImage(data:imageData) else {
			
			// Couldn't create an image
			if data == nil {
				return .Failure(error!)
			}
			else {
				return .Failure(PhotoError.ImageCreationError)
			}
		}
		
		return .Success(image)
	}
	
	// Fetch Photos instances from the main queue context
	func fetchMainQueuePhotos(predicate predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Photo] {
		
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		fetchRequest.sortDescriptors = sortDescriptors
		fetchRequest.predicate = predicate
		
		let mainQueueContext = self.coreDataStack.mainQueueContext
		var mainQueuePhotos: [Photo]?
		var fetchRequestError: ErrorType?
		mainQueueContext.performBlockAndWait() {
			do {
				mainQueuePhotos = try mainQueueContext.executeFetchRequest(fetchRequest) as? [Photo]
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
}