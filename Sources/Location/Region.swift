import Foundation

/// A circular geographic region, specified as a center point and radius.
public struct Region: Codable, Identifiable {
    
    public let id: String
    /// The center point of the geographic area.
    public let center: Coordinates
    /// The radius (measured in meters) that defines the geographic area’s outer boundary.
    public let radius: Double
    
    public init(
        id: String = "",
        center: Coordinates = .init(),
        radius: Double = 100.0
    ) {
        self.id = id
        self.center = center
        self.radius = radius
    }
    
    public var coordinates: Coordinates { center }
}

#if canImport(CoreLocation)
import CoreLocation

public extension Region {
    init(_ region: CLCircularRegion) {
        id = region.identifier
        center = Coordinates(region.center)
        radius = region.radius
    }
}

public extension CLCircularRegion {
    convenience init(_ region: Region) {
        self.init(
            center: CLLocationCoordinate2D(region.center),
            radius: region.radius,
            identifier: region.id
        )
    }
}
#endif
