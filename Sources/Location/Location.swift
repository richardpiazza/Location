import Foundation

/// Represents a geographical coordinate along with accuracy and timestamp information.
public struct Location: Codable {
    /// The latitude and longitude associated with a location.
    public let coordinates: Coordinates
    
    /// The date and time when this location was determined.
    public let timestamp: Date
    
    /// The altitude of the location.
    ///
    /// Can be positive (above sea level) or negative (below sea level).
    public let altitude: Double
    
    /// The course of the location in degrees true North.
    ///
    /// 0.0 - 359.9 degrees, 0 being true North.
    public let course: Double?
    
    /// The horizontal accuracy of the location.
    public let horizontalAccuracy: Double?
    
    /// The vertical accuracy of the location.
    public let verticalAccuracy: Double?
    
    /// The speed of the location in m/s.
    public let speed: Double?
    
    public init(
        coordinates: Coordinates = Coordinates(),
        timestamp: Date = Date(),
        altitude: Double = 0.0,
        course: Double? = nil,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        speed: Double? = nil
    ) {
        self.coordinates = coordinates
        self.timestamp = timestamp
        self.altitude = altitude
        self.course = course
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
    }
}

#if canImport(CoreLocation)
import CoreLocation

public extension Location {
    init(_ location: CLLocation) {
        coordinates = Coordinates(location.coordinate)
        timestamp = location.timestamp
        altitude = location.altitude
        course = (location.course >= 0) ? location.course : nil
        horizontalAccuracy = (location.horizontalAccuracy >= 0.0) ? location.horizontalAccuracy : nil
        verticalAccuracy = (location.verticalAccuracy >= 0.0) ? location.verticalAccuracy : nil
        speed = (location.speed >= 0.0) ? location.speed : nil
    }
}

public extension CLLocation {
    convenience init(_ location: Location) {
        self.init(
            coordinate: CLLocationCoordinate2D(location.coordinates),
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy ?? -1.0,
            verticalAccuracy: location.verticalAccuracy ?? -1.0,
            course: location.course ?? -1.0,
            speed: location.speed ?? -1.0,
            timestamp: location.timestamp
        )
    }
}
#endif
