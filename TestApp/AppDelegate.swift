//
//  AppDelegate.swift
//  TestApp
//
//  Created by Michael Redig on 2/22/19.
//  Copyright © 2019 Michael Redig. All rights reserved.
//

import Cocoa
import SwiftyLetsMove

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		LetsMove.shared.moveToApplicationsFolderIfNecesary()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

