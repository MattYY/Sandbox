//
//  Tests.swift
//  Tests
//
//  Created by Matthew Yannascoli on 4/19/16.
//  Copyright © 2016 Matthew Yannascoli. All rights reserved.
//

import XCTest
@testable import Sandbox


class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreationOfValidSandboxSucceeds() {
        do {
            let _ = try Sandbox(baseDirectory: .DocumentDirectory, name: "TestSandbox")
        }
        catch {
            XCTFail()
        }
    }
    
    func testFileCreation() {
        let sandbox = try! Sandbox(baseDirectory: .DocumentDirectory, name: "TestSandbox")
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(sandbox.path)
        XCTAssertTrue(fileExists)
    }
    
    func testFileDeletion() {
        let sandbox = try! Sandbox(baseDirectory: .DocumentDirectory, name: "TestSandbox")
        try! sandbox.delete()
        
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(sandbox.path)
        XCTAssertFalse(fileExists)
    }
    
}
