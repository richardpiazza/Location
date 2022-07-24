import Foundation

public struct PostalAddress: Hashable, Codable {
    public let street: String
    public let city: String
    public let state: String
    public let postalCode: String
    
    public init(
        street: String = "",
        city: String = "",
        state: String = "",
        postalCode: String = ""
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
    }
    
    public init(
        street1: String,
        street2: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = ""
    ) {
        self.street = !street2.isEmpty ? "\(street1)\n\(street2)" : street1
        self.city = city
        self.state = state
        self.postalCode = zipCode
    }
}

extension PostalAddress: CustomStringConvertible {
    public var description: String {
        "\(street), \(city), \(state) \(postalCode)"
    }
}

#if canImport(Contacts)
import Contacts

public extension CNMutablePostalAddress {
    convenience init(_ postalAddress: PostalAddress) {
        self.init()
        street = postalAddress.street
        city = postalAddress.city
        state = postalAddress.state
        postalCode = postalAddress.postalCode
    }
}
#endif
