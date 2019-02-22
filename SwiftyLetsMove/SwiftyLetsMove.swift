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
			return
		}
		
		let bundlePath = letsMoveBundle.bundlePath
		//FIXME: change to guard statement if unused elsewhere
		let isNestedApp = isApplicationNested(atPath: bundlePath)
		
		guard !isInApplicationsFolder(atPath: bundlePath) else { return }
		
		moveIsInProgress = true
		
		// are we on a disk image?
//		let diskImageDevice =
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
	
	func isOnDiskImage(with bundlepath: String) -> Bool {
		let containingPath = (bundlepath as NSString).deletingLastPathComponent
		
		var diskImageMountPaths = [String]()
		
		let diskImageInfo = getDiskImageInfo()
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
