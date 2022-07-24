// Source: https://github.com/richardpiazza/CoreDataPlus

import Foundation
#if canImport(CoreData)
import CoreData

public extension String {
    /// A Core Data `NSManagedObjectModel`.
    static let xcdatamodeld: String = "xcdatamodeld"
    /// Extension for processed/compiled `NSManagedObjectModel`s.
    static let momd: String = "momd"
    /// A Core Data `NSMappingModel`.
    static let xcmappingmodel: String = "xcmappingmodel"
    /// Extension for processed/compiled `NSMappingModel`s.
    static let cdm: String = "cdm"
    /// Suffix appended to Copy resources.
    static let precompiled: String = "_precompiled"
}

public extension Bundle {
    enum ResourceError: LocalizedError {
        case notFound(_ resource: String, _ bundle: Bundle)
        case contents(_ type: Any.Type, _ path: String)
        
        public var errorDescription: String? {
            switch self {
            case .notFound(let resource, let bundle):
                return "No URL for Resource '\(resource)' in Bundle '\(bundle.bundlePath)'."
            case .contents(let type, let path):
                return "Unable to load contents of \(type) at URL '\(path)'."
            }
        }
    }
    
    /// Retrieve a `NSManagedObjectModel` from the bundle.
    ///
    /// When correctly recognized and processed as a resource, `.xcdatamodeld` will be automatically compiled and
    /// presented as a `.momd` folder. In some instances (such as utilizing through the macOS command line) the resource
    /// is not processed. To account for this situation, a secondary URL {resource}.momd_precompiled will be checked.
    ///
    /// You can manually pre-compile `NSManagedObjectModel`s using the `momc` command found in the Xcode.app bundle.
    /// `/Applications/Xcode.app/Contents/Developer/usr/bin/momc`.
    ///
    /// - parameter resource: The name of the resource file (without extension)
    func managedObjectModel(forResource resource: String) throws -> NSManagedObjectModel {
        let url: URL
        
        if let _url = self.url(forResource: resource, withExtension: .momd) {
            url = _url
        } else if let _url = self.url(forResource: resource, withExtension: "\(String.momd)\(String.precompiled)") {
            url = _url
        } else {
            throw ResourceError.notFound(resource, self)
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            throw ResourceError.contents(NSManagedObjectModel.self, url.path)
        }
        
        return model
    }
    
    /// Retrieve a `NSMappingModel` from the bundle.
    ///
    /// When correctly recognized and processed as a resource, `.xcmappingmodel` will be automatically compiled and
    /// presented as a `.cdm` file. In some instances (such as utilizing through the macOS command line) the resource
    /// is not processed. To account for this situation, a secondary URL {resource}.cdm_precompiled will be checked.
    ///
    /// You can manually pre-compile `NSMappingModel`s using the `mapc` command found in the Xcode.app bundle.
    /// `/Applications/Xcode.app/Contents/Developer/usr/bin/mapc`.
    ///
    /// - parameter resource: The name of the resource file (without extension)
    func mappingModel(forResource resource: String) throws -> NSMappingModel {
        let url: URL
        
        if let _url = self.url(forResource: resource, withExtension: .cdm) {
            url = _url
        } else if let _url = self.url(forResource: resource, withExtension: "\(String.cdm)\(String.precompiled)") {
            url = _url
        } else {
            throw ResourceError.notFound(resource, self)
        }
        
        guard let mapping = NSMappingModel(contentsOf: url) else {
            throw ResourceError.contents(NSMappingModel.self, url.path)
        }
        
        return mapping
    }
}
#endif
