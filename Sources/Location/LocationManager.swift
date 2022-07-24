import Foundation
import Combine

public protocol LocationManager: AnyObject {
    var authorization: ManagerAuthorization { get }
    var authorizationPublisher: AnyPublisher<ManagerAuthorization, Never> { get }
    var isLocating: Bool { get }
    var isLocatingPublisher: AnyPublisher<Bool, Never> { get }
    
    /// The last known `Location`
    var lastLocation: Location? { get }
    /// Publisher that emits when your location changes.
    ///
    /// - note: This publisher does not trigger any location services.
    var locationObservationPublisher: AnyPublisher<Location?, Never> { get }
    
    func requestAuthorization()
    
    func coordinates(for postalAddress: PostalAddress) async -> Coordinates?
    /// Estimated distance between `Coordinates` measured in meters.
    func distance(to coordinates: Coordinates, from location: Location) -> Double?
    
    /// Publisher that emits a single location and completes.
    func currentLocation(withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError>
    
    /// Publisher that emits location updates.
    ///
    /// Updates will continue as long as the subscription is maintained.
    func beginPositioning(forActivity activityType: ActivityType, withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError>
    
    func monitorRegion(_ region: Region) -> AnyPublisher<GeoFence, LocationError>
}

public extension LocationManager {
    var authorized: Bool { authorization == .authorizedAlways || authorization == .authorizedWhenInUse }
    
    func ensureAuthorized() -> AnyPublisher<ManagerAuthorization, LocationError> {
        requestAuthorization()
        
        return authorizationPublisher
            .tryFilter { authorization in
                switch authorization {
                case .authorizedAlways, .authorizedWhenInUse:
                    return true
                default:
                    return false
                }
            }
            .first()
            .mapError { LocationError($0) }
            .eraseToAnyPublisher()
    }
}
