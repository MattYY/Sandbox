//
//  Sandbox.swift
//  Sandbox
//
//  Created by Matthew Yannascoli on 4/19/16.
//  Copyright © 2016 Matthew Yannascoli. All rights reserved.
//

import Foundation


/// A super simple wrapper for managing paths/urls for a directory that lives
/// outside of the application bundle. This can be useful for segmenting user
/// specific resources.
public struct Sandbox: CustomStringConvertible {
    private let name: String
    private let directory: NSSearchPathDirectory
    private let fileProtection: FileProtection
    
    private let baseURL: NSURL
    
    /// `FileProtection` is a one-to-one mapping to NSFile's default data encryption options.
    //// Although any file attribute can be applied to any sandbox directory using
    ///  NSFileManager's setAttributes method at any time outside of this API the file protection
    ///  options are specifically elevated to encourage security best practices.
    public enum FileProtection : String {
        /// No file protection
        case None
        /// NSFileProtectionComplete: Files are protected ten seconds after the device is locked.
        case Complete
        /// NSFileProtectionCompleteUnlessOpen: Files are protected ten seconds after the device
        /// is locked unless they’re currently open
        case CompleteUnlessOpen
        /// NSFileProtectionCompleteUntilFirstAuthentication: Files are protected only between 
        /// the time the device boots and the first time the user unlocks the device.
        case CompleteUntilFirstAuthentication
    }
    
    ///Useful for printing the url value
    public var description: String {
        return url.description
    }
    
    ///Custom errors
    public enum SandboxError: ErrorType, CustomDebugStringConvertible {
        /// Occurs if theres an issue creating the sandbox during initialization.
        case CreationError(error: NSError)
        /// Occurs if there is an error deleting the sandbox in a call to the `delete` method.
        case DeletionError(error: NSError)
        public var debugDescription: String {
            switch self {
            case .CreationError(let error):
                return "Unable to create directory (sandbox) with error: \(error.localizedDescription)"
            case .DeletionError(let error):
                return "Unable to remove directory (sandbox) with error: \(error.localizedDescription)"
            }
        }
    }
}


//MARK: - Initializers -
/// Initializers
extension Sandbox {
    /// Creates a system folder at the specified `baseDirectory`/`name` location.
    /// If directory creation fails this will throw a `DirectoryCreationError`.
    public init(baseDirectory: NSSearchPathDirectory, name: String, fileProtection: FileProtection = .Complete) throws {
        self.name = name
        self.directory = baseDirectory
        self.fileProtection = fileProtection
        
        let documentsPath = NSFileManager.defaultManager().URLsForDirectory(
            .DocumentDirectory, inDomains: .UserDomainMask).last!
        
        self.baseURL = documentsPath.URLByAppendingPathComponent("\(name)")
        
        //
        try createDirectoryIfNecessary()
    }
    
    /// Convenience initializer for creating a sandbox in the `DocumentDirectory`
    public init(inDocumentsWithName name: String, fileProtection: FileProtection = .Complete) throws {
        try self.init(baseDirectory: .DocumentDirectory, name: name, fileProtection: fileProtection)
    }
    
    /// Convenience initializer for creating a sandbox in the `ApplicationSupportDirectory`
    public init(inApplicationSupportWithName name: String, fileProtection: FileProtection = .Complete) throws {
        try self.init(baseDirectory: .ApplicationSupportDirectory, name: name, fileProtection: fileProtection)
    }
    
    /// Convenience initializer for creating a sandbox in the `CachesDirectory`
    public init(inCachesWithName name: String, fileProtection: FileProtection = .Complete) throws {
        try self.init(baseDirectory: .CachesDirectory, name: name, fileProtection: fileProtection)
    }
}




//MARK: - API -
/// Initializers
extension Sandbox {
    /// Returns an NSURL representing the provided `baseDirectory`/`name` combination.
    public var url: NSURL {
        return baseURL
    }
    
    /// Returns a relative path representing the provided `baseDirectory`/`name` combination.
    /// A relative path is preferred here because the system will error when creating a
    /// resource that contains a scheme, for example "file://".
    public var path: String {
        return baseURL.relativePath!
    }
    
    /// Permanently removes the sandbox directory and everything in it so ¡BE CAREFUL! when
    /// using this method.
    public func delete() throws {
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtURL(url)
        }
        catch let error as NSError {
            throw error
        }
    }
}



//MARK: - Utilities -
extension Sandbox {
    private func createDirectoryIfNecessary() throws {
        //Create the container if necessary
        var error:NSError?
        if !url.checkResourceIsReachableAndReturnError(&error) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(
                    url, withIntermediateDirectories: true, attributes: nil)
                
                try setDataProtection()
            }
            catch let error as NSError {
                throw SandboxError.CreationError(error: error)
            }
        }
    }
    
    private func setDataProtection() throws {
        var attributes: [String : AnyObject]?
        
        switch fileProtection {
        case .Complete:
            attributes = [NSFileProtectionKey: NSFileProtectionComplete]
        case .CompleteUnlessOpen:
            attributes = [NSFileProtectionKey: NSFileProtectionCompleteUnlessOpen]
        case .CompleteUntilFirstAuthentication:
            attributes = [NSFileProtectionKey: NSFileProtectionCompleteUnlessOpen]
        default:
            break
        }
        
        if let attributes = attributes {
            try NSFileManager.defaultManager().setAttributes(attributes, ofItemAtPath: path)
        }
    }
}
