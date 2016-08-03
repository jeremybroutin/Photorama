//
//  PhotosViewController.swift
//  Photorama
//
//  Created by Jeremy Broutin on 5/2/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    
	@IBOutlet var collectionView: UICollectionView!
	@IBOutlet var searchField: UIBarButtonItem!
	
	var store: PhotoStore! // reference to an instance of PhotoStore
	let photoDataSource = PhotoDataSource() // reference an instance of PhotoDataSource
	
	var helloView: UIView!
    
    // Note: the "store" is a dependency of the PhotosViewController
    // We use property injection in the AppDelegate to give the PhotosVC its "store" dependency.
    // This way the PhotosVC can interact with the PhotoStore
    
	// MARK: - App Life Cycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		collectionView.dataSource = photoDataSource
		collectionView.delegate = self
		
		// Customize navigation bar
		navigationController?.navigationBar.barTintColor = UIColor(red:0.16, green:0.40, blue:0.74, alpha:1.0)
		navigationController?.navigationBar.tintColor = UIColor.whiteColor()
		navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
		
		let leftButton = UIBarButtonItem(title: "Photorama", style: .Plain, target: self, action: nil)
		navigationItem.leftBarButtonItem = leftButton
		
		displayHelloView()
		UIView.animateWithDuration(1, delay: 1, options: [], animations: {
			self.helloView.transform = CGAffineTransformIdentity
			}, completion: nil)
		
		
		// Get most recent photos by default
		store.fetchPhotos(Method.RecentPhotos, keyword: nil){ (photosResult) -> Void in

// Commented out not to store photos in Core Data
//			let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
//			let allPhotos = try! self.store.fetchMainQueuePhotos(predicate: nil, sortDescriptors: [sortByDateTaken])
			
			switch photosResult {
			case .Success(let photos):
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.photoDataSource.photos = photos
					self.collectionView.reloadSections(NSIndexSet(index: 0))
				})
			case .Failure(_):
				break
			}
			
			
		}
    }
	
	// Listen to view size changes
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		setHelloViewConstraints()
	}
	
	override func viewDidLayoutSubviews() {
		//Layout the collectionView cells properly on the View
		let layout = UICollectionViewFlowLayout()
		
		layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
		layout.minimumLineSpacing = 5
		layout.minimumInteritemSpacing = 5
		
		let width = (floor(self.collectionView.frame.size.width / 4)) - 7
		layout.itemSize = CGSize(width: width, height: width)
		
		collectionView.collectionViewLayout = layout
	}
	
	// MARK: - Helper functions
	
	// Initialize the Hello View
	func displayHelloView(){
		
		// slightly hide collection view which will start loading
		collectionView.alpha = 0.2
		
		// create view
		helloView = UIView(frame: CGRectMake(0, 0, 0, 0))
		helloView.transform = CGAffineTransformMakeScale(0, 0)
		
		helloView.backgroundColor = UIColor(red:0.16, green:0.40, blue:0.74, alpha:1.0)
		helloView.layer.cornerRadius = 5
		helloView.layer.shadowColor = UIColor.darkGrayColor().CGColor
		helloView.layer.shadowOpacity = 0.6
		helloView.layer.shadowOffset = CGSizeMake(0, 2)
		helloView.layer.shadowRadius = 1
		helloView.layer.shouldRasterize = true
		
		helloView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(helloView)
		
		// setup constraint
		setHelloViewConstraints()
		
		// create label subview: label
		// create label subview: button
		
	}
	
	// Set Hello View constraints
	func setHelloViewConstraints(){
		
		//remove any previous constraints
		for constraint in view.constraints {
			if constraint.firstItem as! UIView == helloView && constraint.secondItem as! UIView == view {
				view.removeConstraint(constraint)
			}
		}
		
		// check device orientation and add constraints consequently
		if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
			let xAxisConstraint = NSLayoutConstraint(item: helloView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
			let yAxisConstraint = NSLayoutConstraint(item: helloView, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0)
			let widthConstraint = NSLayoutConstraint(item: helloView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: -100)
			let heightConstraint = NSLayoutConstraint(item: helloView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -150)
			view.addConstraints([xAxisConstraint, yAxisConstraint, widthConstraint, heightConstraint])
		}
		if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation){
			let xAxisConstraint = NSLayoutConstraint(item: helloView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
			let yAxisConstraint = NSLayoutConstraint(item: helloView, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0)
			let widthConstraint = NSLayoutConstraint(item: helloView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: -100)
			let heightConstraint = NSLayoutConstraint(item: helloView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -300)
			view.addConstraints([xAxisConstraint, yAxisConstraint, widthConstraint, heightConstraint])
		}
	}
	
	
	// We will download the image data for only the cells that the user is attempting to view
	// using the UICollectionView delegate method willDisplayCell.
	// Best practice in order to only download what we need and prevent a costly operation.
	
	func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
		
		let photo = photoDataSource.photos[indexPath.row]
		
		// Download the image data, which could take some time
		store.fetchImageForPhoto(photo) { (result) in
			
			NSOperationQueue.mainQueue().addOperationWithBlock({ 
				// The index path for the photo might have changed between the tine the request started
				// and finished, so find the most recent index path
				
				let photoIndex = self.photoDataSource.photos.indexOf(photo)!
				let photoIndexPath = NSIndexPath(forRow: photoIndex, inSection: 0)
				
				// When the request finishes, only update the cell if it's still visible
				if let cell = self.collectionView.cellForItemAtIndexPath(photoIndexPath) as? PhotoCollectionViewCell {
					cell.updateWithImage(photo.image)
				}
			})
		}
	}
	
	// Prepare segue to pass store and photo to the next controller
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showPhoto" {
			if let selectedIndexPath = collectionView.indexPathsForSelectedItems()?.first {
				let photo = photoDataSource.photos[selectedIndexPath.row]
				let destinationVC = segue.destinationViewController as! PhotoInfoViewController
				destinationVC.photo = photo
				destinationVC.store = store
			}
		}
	}
}

extension PhotosViewController: UITextFieldDelegate {
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
		textField.addSubview(activityIndicator)
		activityIndicator.frame = textField.bounds
		activityIndicator.startAnimating()
		
		store.fetchPhotos(Method.Search, keyword: textField.text) { (photosResult) in
			
			switch photosResult {
			case .Success(let photos):
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.photoDataSource.photos = photos
					self.collectionView.reloadSections(NSIndexSet(index: 0))
				})
			case .Failure(_):
				break
			}
		}
		activityIndicator.stopAnimating()
		activityIndicator.removeFromSuperview()
		textField.text = "Search..."
		textField.resignFirstResponder()
		return true
	}
}
