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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
	
	func testNestedApplicationDetection() {
		let nestedPathDownloads = "/Users/theUser/Downloads/Application1.app/Contents/Resources/Application2.app" as NSString
		let nestedPathApplications = "/Applications/Application1.app/Contents/Resources/Application2.app" as NSString
		let unnestedPathDownloads = "/Users/theUser/Downloads/Application1.app" as NSString
		let unnestedPathApplications = "/Applications/Application1.app" as NSString
		
		XCTAssertTrue(LetsMove.shared.isApplicationNested(atPath: nestedPathDownloads))
		XCTAssertTrue(LetsMove.shared.isApplicationNested(atPath: nestedPathApplications))
		XCTAssertFalse(LetsMove.shared.isApplicationNested(atPath: unnestedPathDownloads))
		XCTAssertFalse(LetsMove.shared.isApplicationNested(atPath: unnestedPathApplications))

	}

}
