//
//  HelloView.swift
//  Photorama
//
//  Created by Jeremy Broutin on 8/3/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class HelloView: UIView {
	
	var helloText: String = ""
	var continueButton: UIButton!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		didLoad()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		didLoad()
	}
	
	func didLoad(){
		
		superview?.alpha = 0.2
		
		self.transform = CGAffineTransform(scaleX: 0, y: 0)
		
		self.backgroundColor = UIColor(red:0.16, green:0.40, blue:0.74, alpha:1.0)
		self.layer.cornerRadius = 5
		self.layer.shadowColor = UIColor.darkGray.cgColor
		self.layer.shadowOpacity = 0.6
		self.layer.shadowOffset = CGSize(width: 0, height: 2)
		self.layer.shadowRadius = 1
		self.layer.shouldRasterize = true
		
		self.translatesAutoresizingMaskIntoConstraints = false
		setContinueButton()
		self.addSubview(continueButton)
	}
	
	override func didMoveToSuperview() {
		guard superview != nil else { return }
		setConstraints()
	}
	
	func setConstraints(){
		
		//remove any previous constraints
		for constraint in superview!.constraints {
			if constraint.firstItem as! UIView == self && constraint.secondItem as? UIView == superview {
				superview!.removeConstraint(constraint)
			}
		}
		
		// Hello View basic constraints
		let xAxisConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superview, attribute: .centerX, multiplier: 1, constant: 0)
		let yAxisConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superview, attribute: .centerY, multiplier: 1, constant: 0)
		
		// check device orientation and add constraints consequently
		if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
			let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superview, attribute: .width, multiplier: 1, constant: -100)
			let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superview, attribute: .height, multiplier: 1, constant: -150)
			superview!.addConstraints([xAxisConstraint, yAxisConstraint, widthConstraint, heightConstraint])
		}
		if UIDeviceOrientationIsPortrait(UIDevice.current.orientation){
			let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superview, attribute: .width, multiplier: 1, constant: -100)
			let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superview, attribute: .height, multiplier: 1, constant: -300)
			superview!.addConstraints([xAxisConstraint, yAxisConstraint, widthConstraint, heightConstraint])
		}
		
		// Continue Button constraints
		let centerXConstraint = NSLayoutConstraint(item: continueButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
		let bottomConstraint = NSLayoutConstraint(item: continueButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -8)
		self.addConstraints([centerXConstraint, bottomConstraint])
	}
	
	func setContinueButton(){
		continueButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
		continueButton.setTitle("Continue", for: UIControlState())
		continueButton.setTitleColor(UIColor.white, for: UIControlState())
		continueButton.addTarget(self, action: #selector(HelloView.dismissHelloView), for: .touchUpInside)
		continueButton.translatesAutoresizingMaskIntoConstraints = false
	}
	
	func dismissHelloView(){
		UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
			self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
			}) { (result) in
				self.removeFromSuperview()
		}
	}
	
}
