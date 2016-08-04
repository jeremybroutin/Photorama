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
	
	var helloView: HelloView!
	var segmentedControl: UISegmentedControl!
    
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
		
		// Display hello view
		helloView = HelloView(frame: CGRectMake(0, 0, 0, 0))
		view.addSubview(helloView)
		UIView.animateWithDuration(1, delay: 1, options: [], animations: {
			self.helloView.transform = CGAffineTransformIdentity
			}, completion: nil)
		
		
		// Add segmented control
		segmentedControl = UISegmentedControl(items: ["All Photos", "Favourites"])
		segmentedControl.backgroundColor = UIColor(red:0.16, green:0.40, blue:0.74, alpha:1.0)
		segmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
		segmentedControl.layer.cornerRadius = 5
		segmentedControl.selectedSegmentIndex = 0
		segmentedControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(segmentedControl)
		let bottomConstraint = segmentedControl.bottomAnchor.constraintEqualToAnchor(self.bottomLayoutGuide.topAnchor , constant: -8)
		let margins = view.layoutMarginsGuide
		let leadingConstraint = segmentedControl.leadingAnchor.constraintEqualToAnchor(margins.leadingAnchor)
		let trailingConstraint = segmentedControl.trailingAnchor.constraintEqualToAnchor(margins.trailingAnchor)
		bottomConstraint.active = true
		leadingConstraint.active = true
		trailingConstraint.active = true
		segmentedControl.addTarget(self, action: #selector(toggleList(_:)), forControlEvents: .ValueChanged)
		
		// Get most recent photos by default
		store.fetchPhotos(Method.RecentPhotos, keyword: nil){ (photosResult) -> Void in

			let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
			let allPhotos = try! self.store.fetchMainQueuePhotos(predicate: nil, sortDescriptors: [sortByDateTaken])
			
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.photoDataSource.photos = allPhotos
				self.collectionView.reloadSections(NSIndexSet(index: 0))
			})
			
		}
    }
	
	// Listen to view size changes (portrait or landascape) to adapt hello view if necessary
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		if let helloView = helloView {
			helloView.setConstraints()
		}
		
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
				
				if let photoIndex = self.photoDataSource.photos.indexOf(photo){
					let photoIndexPath = NSIndexPath(forRow: photoIndex, inSection: 0)
					
					// When the request finishes, only update the cell if it's still visible
					if let cell = self.collectionView.cellForItemAtIndexPath(photoIndexPath) as? PhotoCollectionViewCell {
						cell.updateWithImage(photo.image)
					}
				}
			})
		}
	}
	
	// Prepare segue to pass store and photo to the next controller
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showPhoto" {
			if let selectedIndexPath = collectionView.indexPathsForSelectedItems()?.first {
				let photo = photoDataSource.photos[selectedIndexPath.row]
				
				// Update views count
				let numberOfViews = Float(photo.viewsCount) + 1.0
				photo.viewsCount = NSNumber(float: numberOfViews)
				do {
					try store.coreDataStack.saveChanges()
				}
				catch let error {
					print ("Error while saving changes on picture viewsCount: \(error)")
				}
				
				let destinationVC = segue.destinationViewController as! PhotoInfoViewController
				destinationVC.photo = photo
				destinationVC.store = store
			}
		}
	}

	func refreshCollection(){
		let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
		var predicate: NSPredicate?
		
		if segmentedControl.selectedSegmentIndex > 0 {
			predicate = NSPredicate(format: "isFavorite == true")
		}
		let allPhotos = try! self.store.fetchMainQueuePhotos(predicate: predicate, sortDescriptors: [sortByDateTaken])
		print("total (CoreData) fetched photos: \(allPhotos.count)")
		NSOperationQueue.mainQueue().addOperationWithBlock() {
			self.photoDataSource.photos = allPhotos
			self.collectionView.reloadSections(NSIndexSet(index: 0))
		}
	}
	
	func toggleList(sender:AnyObject){
		refreshCollection()
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
		textField.resignFirstResponder()
		return true
	}
}
