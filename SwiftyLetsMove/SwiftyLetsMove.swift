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
	private let fileManager = FileManager.default
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
			print("user suppressed lets move")
			return
		}
		
		let bundlePath = Bundle.main.bundlePath
		guard !isApplicationNested(atPath: bundlePath) else {
			failInstall(with: "This application is nested within another. These typically don't get installed to an Apps folder.")
			return
		}
		
		guard !isInApplicationsFolder(atPath: bundlePath) else { return }
		
		moveIsInProgress = true
		
		// are we on a disk image?
		let onDiskImage = isOnDiskImage(with: bundlePath)
		
		//get preferred intall directory
		guard let installDir = getPrefferedInstallDirectory() else {
			failInstall(with: "Can't write to /Applications or ~/Applications")
			return
		} //couldn't get an install directory
		
		let bundleName = (bundlePath as NSString).lastPathComponent
		let destinationPath = (installDir as NSString).appendingPathComponent(bundleName)
		
		//check if we can overwrite any existing copy of the app in the destination directory
		if fileManager.fileExists(atPath: destinationPath) && !fileManager.isWritableFile(atPath: destinationPath) {
			failInstall(with: "Can't overwrite '\(destinationPath)'")
			return
		}
		
		let response = OMGAlrt.showAlert(withTitle: "Move to \(installDir)?", andMessage: "I can move myself to \(installDir) if you'd like. This will keep your Downloads folder uncluttered.", andConfirmButtonText: "Move to Applications Folder", withCancelButtonText: "Don't Move", withAlertStyle: .informational) { (alert) in
			
			if alert.suppressionButton?.state == .on {
				UserDefaults.standard.set(true, forKey: self.alertSuppressKey)
			}
		}
		
		if response == .alertFirstButtonReturn { //proceed with install
			//move
			
			//if a copy already exists at the destination, move it to the trash
			if fileManager.fileExists(atPath: destinationPath) {
				// confirm it's not running
				if isApplicationRunning(atPath: destinationPath) {
					failInstall(with: "Another version is already installed at this path. Please close it and try again.") {
						NSApp.terminate(nil)
					}
				} else { //it's not running, so can proceed
					guard trashItem(atPath: destinationPath) else {
						failInstall(with: "Could not trash the old Application. Please delete it yourself and try again.") {
							NSApp.terminate(nil)
						}
						return
					}
				}
			}
			
			// copy the running app to the destination
			guard copyBundle(from: bundlePath, to: destinationPath) else {
				failInstall(with: "Could not copy myself to \(destinationPath)") {
					NSApp.terminate(nil)
				}
				return
			}
			
			// trash the original app
			if !onDiskImage {
				trashItem(atPath: bundlePath)
			}
			
			//relaunch
			relaunch(atPath: destinationPath)
			
			moveIsInProgress = false
			NSApp.terminate(nil)
			
		}
		
	}
	
	func failInstall(with message: String = "") {
		failInstall(with: message) {
			//
		}
	}
	
	func failInstall(with message: String = "", _ cleanup: () -> ()) {
		moveIsInProgress = false
		
		// pop up alert stating that it failed with message, then continue on to the actual app
		OMGAlrt.showAlert(withTitle: "Can't Move", andMessage: message, withCancelButtonText: nil) { (alert) in
			
		}
		
		
		cleanup()
	}
	
	//MARK: - Support functions
	
	func relaunch(atPath path: String) {
		// wait until the original app process terminates
		let pid = ProcessInfo.processInfo.processIdentifier
		
		let quotedDestPath = shellQuotedString(path)
		let quarantineCommand = "/usr/bin/xattr -d -r com.apple.quarantine \(quotedDestPath)"
		
		let script = "(while /bin/kill -0 \(pid) >&/dev/null; do /bin/sleep 0.1; done; \(quarantineCommand); /usr/bin/open \(quotedDestPath)) &"
		
		Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", script]) //seemingly lets you exit the main thread while continuing this script
	}
	
	func shellQuotedString(_ string: String) -> String {
		let rStr = string.replacingOccurrences(of: "'", with: "'\\''")
		return "'\(rStr)'"
	}
	
	
	func copyBundle(from sourcePath: String, to destinationPath: String) -> Bool {
		do {
			try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
			return true
		} catch {
			NSLog("ERROR: Could not copy '\(sourcePath)' to '\(destinationPath)': \(error)")
			return false
		}
	}
	
	@discardableResult func trashItem(atPath path: String) -> Bool {
		let itemURL = URL(fileURLWithPath: path)
		do {
			try fileManager.trashItem(at: itemURL, resultingItemURL: nil)
		} catch {
			return false
		}
		return true
	}
	
	func isApplicationRunning(atPath bundlePath: String) -> Bool {
		let bundlePath = (bundlePath as NSString).standardizingPath
		let runningApps = NSWorkspace.shared.runningApplications
		
		for runningApp in runningApps {
			guard let runningBundlePath = runningApp.bundleURL?.path else { continue }
			let standardizedPath = (runningBundlePath as NSString).standardizingPath
			if standardizedPath == bundlePath {
				return true
			}
		}
		return false
	}
	
	func getPrefferedInstallDirectory() -> String? {
		let computerApplications = "/Applications/"
		let userApplications = ("~/Applications/" as NSString).expandingTildeInPath
		if fileManager.isWritableFile(atPath: computerApplications) {
			return computerApplications
		}
		
		if !fileManager.fileExists(atPath: userApplications) {
			do {
				try fileManager.createDirectory(atPath: userApplications, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print("Coudln't write to user application folder (\(userApplications))")
				return nil
			}
		}
		return userApplications
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
	
	func isInApplicationsFolder(atPath bundlePath: String) -> Bool {
		let bundlePath = bundlePath as NSString
		
		//check normal app directories
		let appDirs = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .allDomainsMask, true)
		for appDir in appDirs {
			if bundlePath.hasPrefix(appDir) { return true }
		}
		
		// check for non standard application directories (perhaps another drive)
		if bundlePath.pathComponents.contains("Applications") { return true }
		return false
	}
	
	
	//MARK:- Disk image stuff
	func isOnDiskImage(with bundlepath: String) -> Bool {
		let containingPath = (bundlepath as NSString).deletingLastPathComponent
		
		var diskImageMountPaths = Set<String>()
		
		guard let diskImageInfo = getDiskImageInfo() else { return false }
		for image in diskImageInfo.images {
			if image.imagePath.lowercased().contains(".dmg") {
				for entity in image.systemEntities {
					guard let mountPoint = entity.mountPoint else { continue }
					diskImageMountPaths.insert(mountPoint)
				}
			}
		}
		
		for mountPoint in diskImageMountPaths {
			if containingPath.contains(mountPoint) {
				return true
			}
		}
		
		return false
	}
	
	func getDiskImageInfo() -> DiskImageInfo? {
		let stuff = SystemUtility.shell(["hdiutil", "info", "-plist"])
		guard let plistData = stuff.stdOut.data(using: .utf8) else { return nil }
		let decoder = PropertyListDecoder()
		return try? decoder.decode(DiskImageInfo.self, from: plistData)
	}

	struct DiskImageInfo: Decodable {
		var images: [MountedDisk]
	}
	
	struct MountedDisk: Decodable {
		enum CodingKeys: String, CodingKey {
			case imagePath = "image-path"
			case imageType = "image-type"
			case writeable
			case systemEntities = "system-entities"
		}
		var imagePath: String
		var imageType: String
		var writeable: Bool
		var systemEntities: [SystemEntities]
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			imagePath = try container.decode(String.self, forKey: .imagePath)
			imageType = try container.decode(String.self, forKey: .imageType)
			writeable = try container.decode(Bool.self, forKey: .writeable)
			systemEntities = try container.decodeIfPresent([SystemEntities].self, forKey: .systemEntities) ?? [SystemEntities]()
		}
	}
	
	struct SystemEntities: Decodable {
		enum CodingKeys: String, CodingKey {
			case contentHint = "content-hint"
			case devEntry = "dev-entry"
			case mountPoint = "mount-point"
		}
		var contentHint: String
		var devEntry: String
		var mountPoint: String?

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			contentHint = try container.decodeIfPresent(String.self, forKey: .contentHint) ?? ""
			devEntry = try container.decodeIfPresent(String.self, forKey: .devEntry) ?? ""
			mountPoint = try container.decodeIfPresent(String.self, forKey: .mountPoint)
		}
	}
	
	
}
