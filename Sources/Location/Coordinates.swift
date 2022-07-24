import Foundation

/// The latitude and longitude associated with a location.
///
/// Specified using the WGS 84 reference frame.
public struct Coordinates: Codable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double = 0.0, longitude: Double = 0.0) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

#if canImport(CoreLocation)
import CoreLocation
public extension Coordinates {
    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

public extension CLLocationCoordinate2D {
    init(_ coordinates: Coordinates) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

public extension CLLocation {
    convenience init(_ coordinates: Coordinates) {
        self.init(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}
#endif
