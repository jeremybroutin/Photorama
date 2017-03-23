//
//  TagsViewController.swift
//  Photorama
//
//  Created by Jeremy Broutin on 8/3/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import CoreData

class TagsViewController: UITableViewController {
	
	var store: PhotoStore!
	var photo: Photo!
	
	// keep track of currently selected tags
	var selectedIndexPath = [IndexPath]()
	
	let tagDataSource = TagDataSource()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.dataSource = tagDataSource
		
		updateTags()
	}
	
	func updateTags(){
		let tags = try! store.fetchMainQueueTags(predicate: nil, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
		tagDataSource.tags = tags
		
		for tag in photo.tags {
			if let index = tagDataSource.tags.index(of: tag) {
				let indexPath = IndexPath(row: index, section: 0)
				selectedIndexPath.append(indexPath)
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let tag = tagDataSource.tags[indexPath.row]
		
		if let index = selectedIndexPath.index(of: indexPath) {
			selectedIndexPath.remove(at: index)
			photo.removeTagObject(tag)
		} else {
			selectedIndexPath.append(indexPath)
			photo.addTagObject(tag)
		}
		
		tableView.reloadRows(at: [indexPath], with: .automatic)
		do {
			try store.coreDataStack.saveChanges()
		}
		catch let error {
			print("Core Data save failed: \(error)")
		}
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		
		if selectedIndexPath.index(of: indexPath) != nil {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
	}
	
	@IBAction func done(_ sender: UIBarButtonItem) {
		presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func addNewTag(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: "Add Tag", message: nil, preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.placeholder = "tag name"
			textField.autocapitalizationType = .words
		}
		
		let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
			if let tagName = alertController.textFields?.first!.text {
				let context = self.store.coreDataStack.mainQueueContext
				let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: context)
				newTag.setValue(tagName, forKey: "name")
				
				do {
					try self.store.coreDataStack.saveChanges()
				}
				catch let error {
					print("Core Data save failed: \(error)")
				}
				self.updateTags()
				self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
			}
		})
		alertController.addAction(okAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		present(alertController, animated: true, completion: nil)
	}
}
