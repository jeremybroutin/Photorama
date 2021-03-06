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
		navigationController?.navigationBar.tintColor = UIColor.white
		navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
		
		let leftButton = UIBarButtonItem(title: "Photorama", style: .plain, target: self, action: nil)
		navigationItem.leftBarButtonItem = leftButton
		
//		// Display hello view
//		helloView = HelloView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
//		view.addSubview(helloView)
//		UIView.animate(withDuration: 1, delay: 1, options: [], animations: {
//			self.helloView.transform = CGAffineTransform.identity
//			}, completion: nil)
		
		
		// Add segmented control
		segmentedControl = UISegmentedControl(items: ["All Photos", "Favourites"])
		segmentedControl.backgroundColor = UIColor(red:0.16, green:0.40, blue:0.74, alpha:1.0)
		segmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .selected)
		segmentedControl.layer.cornerRadius = 5
		segmentedControl.selectedSegmentIndex = 0
		segmentedControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(segmentedControl)
		let bottomConstraint = segmentedControl.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor , constant: -8)
		let margins = view.layoutMarginsGuide
		let leadingConstraint = segmentedControl.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
		let trailingConstraint = segmentedControl.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
		bottomConstraint.isActive = true
		leadingConstraint.isActive = true
		trailingConstraint.isActive = true
		segmentedControl.addTarget(self, action: #selector(toggleList(_:)), for: .valueChanged)
		
		// Get most recent photos by default
		store.fetchPhotos(Method.RecentPhotos, keyword: nil){ (photosResult) -> Void in

			let sortByDateTaken = NSSortDescriptor(key: "dateTaken", ascending: true)
			let allPhotos = try! self.store.fetchMainQueuePhotos(predicate: nil, sortDescriptors: [sortByDateTaken])
			
			OperationQueue.main.addOperation({
				self.photoDataSource.photos = allPhotos
				self.collectionView.reloadSections(IndexSet(integer: 0))
			})
			
		}
    }
	
	// Listen to view size changes (portrait or landascape) to adapt hello view if necessary
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		let photo = photoDataSource.photos[indexPath.row]
		
		// Download the image data, which could take some time
		store.fetchImageForPhoto(photo) { (result) in
			
			OperationQueue.main.addOperation({ 
				// The index path for the photo might have changed between the tine the request started
				// and finished, so find the most recent index path
				
				if let photoIndex = self.photoDataSource.photos.index(of: photo){
					let photoIndexPath = IndexPath(row: photoIndex, section: 0)
					
					// When the request finishes, only update the cell if it's still visible
					if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
						cell.updateWithImage(photo.image)
					}
				}
			})
		}
	}
	
	// Prepare segue to pass store and photo to the next controller
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showPhoto" {
			if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
				let photo = photoDataSource.photos[selectedIndexPath.row]
				
				// Update views count
				let numberOfViews = Float(photo.viewsCount) + 1.0
				photo.viewsCount = NSNumber(value: numberOfViews as Float)
				do {
					try store.coreDataStack.saveChanges()
				}
				catch let error {
					print ("Error while saving changes on picture viewsCount: \(error)")
				}
				
				let destinationVC = segue.destination as! PhotoInfoViewController
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
		OperationQueue.main.addOperation() {
			self.photoDataSource.photos = allPhotos
			self.collectionView.reloadSections(IndexSet(integer: 0))
		}
	}
	
	func toggleList(_ sender:AnyObject){
		refreshCollection()
	}
}

extension PhotosViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		textField.addSubview(activityIndicator)
		activityIndicator.frame = textField.bounds
		activityIndicator.startAnimating()
		
		store.fetchPhotos(Method.Search, keyword: textField.text) { (photosResult) in
			
			switch photosResult {
			case .success(let photos):
				OperationQueue.main.addOperation({
					self.photoDataSource.photos = photos
					self.collectionView.reloadSections(IndexSet(integer: 0))
				})
			case .failure(_):
				break
			}
		}
		activityIndicator.stopAnimating()
		activityIndicator.removeFromSuperview()
		textField.resignFirstResponder()
		return true
	}
}
