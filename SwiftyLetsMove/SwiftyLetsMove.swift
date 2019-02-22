//
//  SwiftyLetsMove.swift
//  SwiftyLetsMove
//
//  Created by Michael Redig on 2/21/19.
//  Copyright © 2019 Michael Redig. All rights reserved.
//

import Foundation

public class LetsMove: NSObject {
	public static let shared = LetsMove()
	
	
	private let alertSuppressKey = "moveToApplicationsFolderAlertSuppress"
	var moveIsInProgress = false
	var letsMoveBundle: Bundle {
		return Bundle(for: type(of: self))
	}

	
	private override init() { //This prevents others initializing their own instances
		super.init()
	}

	
	/**
	Moves the running application to ~/Applications or /Applications if the former does not have write permissions.
	After the move, it relaunches app from the new location.
	DOES NOT work for sandboxed applications.
	
	Call from NSApplication's delegate method `applicationWillFinishLaunching:` method. */
	public func moveToApplicationsFolderIfNecesary() {
		if !Thread.isMainThread { //confirm running on main thread
			DispatchQueue.main.async {
				self.moveToApplicationsFolderIfNecesary()
			}
			return
		}
		
		//skip if user suppressed the alert previously
		if UserDefaults.standard.bool(forKey: alertSuppressKey) {
			return
		}
		
		let bundlePath = letsMoveBundle.bundlePath
		let isNestedApp = isApplicationNested(atPath: bundlePath)
		
	}
	
	func isApplicationNested(atPath bundlePath: String) -> Bool {
		let bundlePath = bundlePath as NSString
		let containingPath = bundlePath.deletingLastPathComponent as NSString
		let components = containingPath.pathComponents as [NSString]
		for component in components {
			if component.pathExtension == "app" {
				return true
			}
		}
		return false
	}
	
	
}
