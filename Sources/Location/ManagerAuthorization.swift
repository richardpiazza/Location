import Foundation

public enum ManagerAuthorization: String, Codable {
    /// User has not yet made a choice with regards to this application
    case notDetermined
    /// This application is not authorized to use location services.
    case restricted
    /// User has explicitly denied authorization for this application, or location services are disabled in Settings.
    case denied
    /// User has granted authorization to use their location at any time.
    case authorizedAlways
    /// User has granted authorization to use their location only while they are using your app.
    case authorizedWhenInUse
}

extension ManagerAuthorization: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined:
            return "User has not yet made a choice with regards to this application"
        case .restricted:
            return "This application is not authorized to use location services."
        case .denied:
            return "User has explicitly denied authorization for this application, or location services are disabled in Settings."
        case .authorizedAlways:
            return "User has granted authorization to use their location at any time."
        case .authorizedWhenInUse:
            return "User has granted authorization to use their location only while they are using your app."
        }
    }
}

#if canImport(CoreLocation)
import CoreLocation

public extension ManagerAuthorization {
    init(_ authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .authorizedWhenInUse:
            self = .authorizedWhenInUse
        case .authorizedAlways:
            self = .authorizedAlways
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        default:
            self = .notDetermined
        }
    }
}
#endif
