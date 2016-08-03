//
//  PhotoDataSource.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/3/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

// Abstract out the collection view data source into a separate class
// to adapt to future potential changes in the app and make this data source reusable as necessary


class PhotoDataSource: NSObject, UICollectionViewDataSource {
	
	// To confornm to the UICollectionViewDataSource protocol, a type also needs to confirm to the NSObjectProtocol
	// Hence why we subclass from NSObject
	
	var photos = [Photo]()
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photos.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UICollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
		let photo = photos[indexPath.row]
		cell.updateWithImage(photo.image)
		
		return cell
	}
	
}
