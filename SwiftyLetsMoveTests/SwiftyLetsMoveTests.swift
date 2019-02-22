//
//  SwiftyLetsMoveTests.swift
//  SwiftyLetsMoveTests
//
//  Created by Michael Redig on 2/21/19.
//  Copyright © 2019 Michael Redig. All rights reserved.
//

import XCTest
@testable import SwiftyLetsMove

class SwiftyLetsMoveTests: XCTestCase {
	let nestedPathDownloads = "/Users/theUser/Downloads/Application1.app/Contents/Resources/Application2.app"
	let nestedPathApplications = "/Applications/Application1.app/Contents/Resources/Application2.app"
	let unnestedPathDownloads = "/Users/theUser/Downloads/Application1.app"
	let unnestedPathApplications = "/Applications/Application1.app"

	var testUnitBundle: Bundle?


    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		testUnitBundle = Bundle.init(for: type(of: self))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testNestedApplicationDetection() {
		XCTAssertTrue(LetsMove.shared.isApplicationNested(atPath: nestedPathDownloads))
		XCTAssertTrue(LetsMove.shared.isApplicationNested(atPath: nestedPathApplications))
		XCTAssertFalse(LetsMove.shared.isApplicationNested(atPath: unnestedPathDownloads))
		XCTAssertFalse(LetsMove.shared.isApplicationNested(atPath: unnestedPathApplications))
	}
	
	func testApplicationDirectoryDetection() {
		XCTAssertTrue(LetsMove.shared.isInApplicationsFolder(atPath: nestedPathApplications))
		XCTAssertTrue(LetsMove.shared.isInApplicationsFolder(atPath: unnestedPathApplications))
		XCTAssertFalse(LetsMove.shared.isInApplicationsFolder(atPath: unnestedPathDownloads))
		XCTAssertFalse(LetsMove.shared.isInApplicationsFolder(atPath: nestedPathDownloads))
	}
	
	func testDiskImageMountInfo() {
		mountDiskImage()
		guard let info = LetsMove.shared.getDiskImageInfo() else {XCTFail("couldn't get dmg info"); return}
		unmountDiskImage()
		
		var foundImage = false
		for image in info.images {
			if image.imagePath.contains("Fake App Image.dmg") {
				foundImage = true
				for entity in image.systemEntities {
					guard let mountPoint = entity.mountPoint else { continue }
					XCTAssertTrue(mountPoint.contains("/Volumes/TheApp"))
				}
			}
		}
		XCTAssertTrue(foundImage)
//		XCTAssert( 1 == 0, "info: \(info!)") //uncomment this if troubleshooting to get output of data (will cause to fail, but will give feedback)
	}
	
	func testDiskImageMountDetection() {
		let onDiskImage = "/Volumes/TheApp/App Name.app"
		let notOnDiskImage = "/Users/theUser/Downloads/unzippedFolder/App Name.app"
		
		mountDiskImage()
		
		XCTAssertTrue(LetsMove.shared.isOnDiskImage(with: onDiskImage))
		XCTAssertFalse(LetsMove.shared.isOnDiskImage(with: notOnDiskImage))
		
		unmountDiskImage()
	}
	
	
	
	
	
	
	//MARK:- Support stuff
	
	func mountDiskImage() {
		guard let dmgPath = testUnitBundle?.path(forResource: "Fake App Image", ofType: "dmg") else {XCTFail("couldn't find dmg"); return}
		guard SystemUtility.shell(["open", dmgPath]).returnCode == 0 else {XCTFail("couldn't mount dmg"); return}
		
		let fm = FileManager.default
		while !fm.fileExists(atPath: "/Volumes/TheApp") { //wait for disk image to fully mount
			sleep(1)
		}
	}
	
	func unmountDiskImage() {
		SystemUtility.shell(["hdiutil", "unmount", "/Volumes/TheApp/"]) //unmount image as its no longer needed.
	}

}
