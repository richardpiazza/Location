import Foundation

extension FileManager {
    /// Locates the **Location** package directory.
    ///
    /// The directory structure will be created as needed. When a group identifier is provided, an attempt will be made
    /// to create and return a directory url that can be shared among multiple app targets.
    ///
    /// - parameters:
    ///   - groupIdentifier: A string that names the group whose shared directory you want to obtain. This input
    ///                      should exactly match one of the strings in the app's App Groups Entitlement.
    func locationDirectory(forSecurityApplicationGroupIdentifier groupIdentifier: String? = nil) throws -> URL {
        let directory: URL
        #if canImport(ObjectiveC)
        if let identifier = groupIdentifier, let url = containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            directory = url
            
            if !fileExists(atPath: directory.path) {
                try createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                print("Created Directory For App Group '\(identifier)'\n\t\(directory.absoluteString)")
            }
        } else {
            directory = try url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        #else
        directory = try url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        #endif
        
        let folder = directory.appendingPathComponent("Location")
        if !fileExists(atPath: folder.path) {
            try createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            print("Created Directory 'Location'\n\t\(folder.absoluteString)")
        }
        
        return folder
    }
}
