import Foundation
#if canImport(CoreData)
import CoreData

@objc(AddressCoordinates)
public class AddressCoordinates: NSManagedObject {

}

extension AddressCoordinates {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AddressCoordinates> {
        return NSFetchRequest<AddressCoordinates>(entityName: "AddressCoordinates")
    }
    
    @NSManaged public var city: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var postalCode: String?
    @NSManaged public var state: String?
    @NSManaged public var street: String?
}
#endif
