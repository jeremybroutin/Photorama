//
//  FlickrAPI.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/2/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import Foundation
import CoreData

// List available methods fromn Flickr API
enum Method: String {
    case RecentPhotos = "flickr.photos.getRecent"
	case Search = "flickr.photos.search"
}

// Use enum with associated values to tie a successful result status of a request with the data
// or tie a failure with error info
enum PhotosResult {
    case Success([Photo])
    case Failure(ErrorType) // ErrorType is a protocol that all errors conform to.
}

// Represent possible errors for the FlickrAPI
enum FlickError: ErrorType {
    case InvalidJSONData
}

struct FlickrAPI {
    
    // type properties and methods are declared with the "static" keyword
    // "private" is used to keep other files from being able to access baseURLString
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let APIKey = "a6d819499131071f158fd740860a5a88"
	
	// instance of NSDateFormatter to convert dateTaken string instance into a NSDate
	private static let dateFormatter: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return formatter
	}()
    
    // private method as this is an implementation detail of the FlickrAPI struct
	private static func flickrURL(method method: Method, parameters: [String:String]?, keyword: String?)-> NSURL {
        let components = NSURLComponents(string: baseURLString)!
        
        var queryItems = [NSURLQueryItem]()
        
        let baseParams = [
            "method": method.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": APIKey
        ]
        
        // loop through base params and add them in NSURLQueryItems
        for (key, value) in baseParams {
            let item = NSURLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        // loop through additional parameters attached to the method and add them too
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = NSURLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
		
		// check if a keyword exists
		if let additionalKeyword = keyword {
			let item = NSURLQueryItem(name: "text", value: additionalKeyword)
			queryItems.append(item)
		}
        
        components.queryItems = queryItems
		
		// debug
		print("components url is: \(String(components.URL!))")
		
		return components.URL!
    }
    
    // internal (default access control level) exposed to the rest of the project
    static func recentPhotosURL() -> NSURL {
        return flickrURL(method: .RecentPhotos, parameters: ["extras": "url_h,date_taken"], keyword: nil)
    }
	
	static func searchPhotosURL(keyword: String) -> NSURL {
		return flickrURL(method: .Search, parameters: ["extras": "url_h,date_taken"], keyword: keyword)
	}
    
    // convert the data into the basic foundation objects
	static func photosFromJSONData(data: NSData, inContext context: NSManagedObjectContext) -> PhotosResult {
        do {
            let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
			
			// guard is a conditional statement that requires execution 
			// to exit the current block if the condition isn't met
            guard let
				jsonDictionary = jsonObject as? [NSObject:AnyObject],
				photos = jsonDictionary["photos"] as? [String:AnyObject],
				photosArray = photos["photo"] as? [[String: AnyObject]] else {
					return .Failure(FlickError.InvalidJSONData)
			}
			
            var finalPhotos = [Photo]()
			for photoJSON in photosArray {
				if let photo = photoFromJSONObject(photoJSON, inContext: context){
					finalPhotos.append(photo)
				}
			}
			
			// Handle the possibility that the JSON format has changed
			if finalPhotos.count == 0 && photosArray.count > 0 {
				// We weren't able to parse any of the photos
				return .Failure(FlickError.InvalidJSONData)
			}
			
            return .Success(finalPhotos)
        }
        catch let error {
            return .Failure(error)
        }
    }
	
	// parse JSON dict into a Photo instance
	private static func photoFromJSONObject(json: [String: AnyObject], inContext context: NSManagedObjectContext) -> Photo? {
		guard let
			photoID = json["id"] as? String,
			title = json["title"] as? String,
			dateString = json["datetaken"] as? String,
			photoURLString = json["url_h"] as? String,
			url = NSURL(string: photoURLString),
			dateTaken = dateFormatter.dateFromString(dateString) else {
				
				// Don't have enough info to construct a Photo
				return nil
		}
		
		
		// First, take the photo ID and look in Core Data if we have a matching photo ID
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		let predicate = NSPredicate(format: "photoID == \(photoID)")
		fetchRequest.predicate = predicate
		
		var fetchedPhotos: [Photo]!
		context.performBlockAndWait { 
			fetchedPhotos = try! context.executeFetchRequest(fetchRequest) as! [Photo]
		}
		// If we do, return early using the retrieved photo in Core data
		if fetchedPhotos.count > 0 {
			
//			WORK IN PROGRESS: ADD NUMBER OF VIEWS ON EACH IMAGE
//			if let viewsCount = fetchedPhotos.first?.viewsCount {
//				var viewsCountInt = Int(viewsCount)
//				viewsCountInt += 1
//				fetchedPhotos.first?.viewsCount = NSNumber(integer: viewsCountInt)
//
//			}
//			need to save the update to the image
			
			return fetchedPhotos.first
		}
		// If we don't continue and create/store the photo object in context
		
		
		// Note: Each NSManagedObjectContext is associated with a specific concurrency queue, and the mainQueueContext is associated
		// with the main queue (or UI queue). Need to interact with a context on the queue that it is associated with using
		// either performBlock (asynchronous) or performBlockAndWait (synchronous).
		// Since we need to return the photo, we need to use the synchronous optio.
		
		var photo: Photo!
		context.performBlockAndWait() {
			photo = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext: context) as! Photo
			photo.title = title
			photo.photoID = photoID
			photo.remoteURL = url
			photo.dateTaken = dateTaken
		}
		
		return photo
	}
}