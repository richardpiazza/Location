import Foundation
#if canImport(CoreData)
import CoreData
#endif

public final class GeoCache {
    
    public static let shared: GeoCache = .init()
    
    private var cacheUrl: URL?
    
    #if canImport(CoreData)
    private lazy var cacheContainer: NSPersistentContainer = {
        let url: URL
        if let cacheUrl = cacheUrl {
            url = cacheUrl
        } else {
            guard let directory = try? FileManager.default.locationDirectory() else {
                preconditionFailure("Failed to initialize 'Location' directory.")
            }
            url = directory.appendingPathComponent("GeoCache.sqlite")
            cacheUrl = url
        }
        
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.type = NSSQLiteStoreType
        description.url = url
        
        guard let model = try? Bundle.module.managedObjectModel(forResource: "GeoCache") else {
            preconditionFailure("Managed Object Model Not Loaded")
        }
        
        let container = NSPersistentContainer(name: "GeoCache", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                preconditionFailure(error.localizedDescription)
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    #else
    private var inMemoryCache: [PostalAddress: Coordinates] = [:]
    #endif
    
    private init() {}
    
    /// Configures the **GeoCache** with an **App Group Identifier**.
    ///
    /// Sandboxed apps that need to share files with other apps from the same developer on a given device
    /// use the App Groups Entitlement to join one or more application groups. The entitlement consists of
    /// an array of group identifier strings that indicate the groups to which the app belongs. You use one of
    /// these group identifier strings to locate the corresponding group's shared directory.
    ///
    /// - parameters:
    ///   - groupIdentifier: A string that names the group whose shared directory you want to
    ///                      obtain. This input should exactly match one of the strings in the app's
    ///                      App Groups Entitlement.
    public func setSecurityApplicationGroupIdentifier(_ groupIdentifier: String) {
        guard let directory = try? FileManager.default.locationDirectory(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            return
        }
        
        let fileUrl = directory.appendingPathComponent("GeoCache.sqlite")
        
        if let cacheUrl = cacheUrl {
            guard cacheUrl != fileUrl else {
                return
            }
            
            #if canImport(CoreData)
            let coordinator = cacheContainer.persistentStoreCoordinator
            
            let existingStores = coordinator.persistentStores
            
            let description = NSPersistentStoreDescription()
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
            description.type = NSSQLiteStoreType
            description.url = fileUrl
            
            var coordinatorError: Swift.Error?
            
            coordinator.addPersistentStore(with: description) { _, error in
                coordinatorError = error
            }
            
            guard coordinatorError == nil else {
                print("Failed to add PersistentStore for App Group '\(groupIdentifier)'.")
                return
            }
            
            existingStores.forEach {
                do {
                    try coordinator.remove($0)
                } catch {
                    print("Failed to remove PersistentStore '\($0)'.")
                }
            }
            #endif
        } else {
            cacheUrl = fileUrl
        }
    }
    
    public func retrieveCoordinates(forAddress address: PostalAddress) -> Coordinates? {
        #if canImport(CoreData)
        let fetch: NSFetchRequest<AddressCoordinates> = AddressCoordinates.fetchRequest()
        fetch.fetchLimit = 1
        fetch.includesPendingChanges = true
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(AddressCoordinates.street), address.street),
            NSPredicate(format: "%K == %@", #keyPath(AddressCoordinates.city), address.city),
            NSPredicate(format: "%K == %@", #keyPath(AddressCoordinates.state), address.state),
            NSPredicate(format: "%K == %@", #keyPath(AddressCoordinates.postalCode), address.postalCode),
        ])

        do {
            guard let addressCoordinates = try cacheContainer.viewContext.fetch(fetch).first else {
                return nil
            }

            return Coordinates(latitude: addressCoordinates.latitude, longitude: addressCoordinates.longitude)
        } catch {
            print(error)
            return nil
        }
        #else
        return inMemoryCache[address]
        #endif
    }
    
    public func persistCoordinates(_ coordinates: Coordinates, forAddress address: PostalAddress) {
        #if canImport(CoreData)
        let context = cacheContainer.newBackgroundContext()

        let addressCoordinates = AddressCoordinates(context: context)
        addressCoordinates.street = address.street
        addressCoordinates.city = address.city
        addressCoordinates.state = address.state
        addressCoordinates.postalCode = address.postalCode
        addressCoordinates.latitude = coordinates.latitude
        addressCoordinates.longitude = coordinates.longitude

        do {
            try context.save()
        } catch {
            print(error)
        }
        #else
        inMemoryCache[address] = coordinates
        #endif
    }
}
