import Foundation
import Logging
import Combine
#if canImport(Contacts)
import Contacts
#endif
#if canImport(CoreLocation)
import CoreLocation

public class CoreLocationManager: NSObject {
    
    private static let logger = Logger(label: "CoreLocationManager")
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    private let geoCoder: CLGeocoder = .init()
    
    public var authorizationPublisher: AnyPublisher<ManagerAuthorization, Never> { authorizationSubject.eraseToAnyPublisher() }
    public var isLocating: Bool { isLocatingSubject.value }
    public var isLocatingPublisher: AnyPublisher<Bool, Never> { isLocatingSubject.eraseToAnyPublisher() }
    
    private var authorizationSubject: CurrentValueSubject<ManagerAuthorization, Never> = .init(.notDetermined)
    private var isLocatingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private var locationObservationSubject: CurrentValueSubject<Location?, Never> = .init(nil)
    private var locationSubject: PassthroughSubject<Location, LocationError> = .init()
    private var geoFenceSubject: PassthroughSubject<GeoFence, LocationError> = .init()
    
    public override init() {
        super.init()
        authorizationSubject = .init(ManagerAuthorization(locationManager.authorizationStatus))
        
        if let location = locationManager.location {
            locationObservationSubject.send(Location(location))
        }
    }
}

extension CoreLocationManager: LocationManager {
    public var authorization: ManagerAuthorization { ManagerAuthorization(locationManager.authorizationStatus) }
    public var lastLocation: Location? { locationObservationSubject.value }
    public var locationObservationPublisher: AnyPublisher<Location?, Never> { locationObservationSubject.eraseToAnyPublisher() }
    
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func coordinates(for postalAddress: PostalAddress) async -> Coordinates? {
        #if canImport(Contacts)
        let geoPostalAddress = CNMutablePostalAddress(postalAddress)
        
        guard let results = try? await geoCoder.geocodePostalAddress(geoPostalAddress) else {
            return nil
        }
        #else
        guard let results = try? await geoCoder.geocodeAddressString(postalAddress.description) else {
            return nil
        }
        #endif
        
        guard let location = results.first?.location else {
            return nil
        }
        
        return Coordinates(location.coordinate)
    }
    
    public func distance(to coordinates: Coordinates, from location: Location) -> Double? {
        let destination = CLLocation(coordinates)
        let origin = CLLocation(location)
        return origin.distance(from: destination)
    }
    
    private func beginLocationUpdates(forActivity activityType: ActivityType, withAccuracy accuracy: Accuracy) {
        locationManager.activityType = CLActivityType(activityType)
        locationManager.desiredAccuracy = CLLocationAccuracy(accuracy)
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        Self.logger.info("Beginning Positioning")
    }
    
    private func endLocationUpdates() {
        Self.logger.info("Ending Positioning")
        locationManager.stopUpdatingLocation()
    }
    
    public func currentLocation(withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError> {
        authorizationPublisher
            .tryFilter { authorization in
                switch authorization {
                case .authorizedAlways, .authorizedWhenInUse: return true
                case .notDetermined: return false
                case .restricted, .denied:
                    throw LocationError.notAuthorized
                }
            }
            .mapError { LocationError($0) }
            .flatMap { _ in
                Future<Void, LocationError> { promise in
                    self.locationSubject = .init()
                    promise(.success(()))
                    self.beginLocationUpdates(forActivity: .otherNavigation, withAccuracy: accuracy)
                }
            }
            .flatMap { _ in
                self.locationSubject
                    .first()
            }
            .handleEvents(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    Self.logger.error("CurrentLocation Completion", metadata: ["localizedDescription": .string(error.localizedDescription)])
                }
                self.endLocationUpdates()
            }, receiveCancel: {
                self.endLocationUpdates()
            })
            .eraseToAnyPublisher()
    }
    
    public func beginPositioning(forActivity activityType: ActivityType, withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError> {
        authorizationPublisher
            .tryFilter { authorization in
                switch authorization {
                case .authorizedAlways, .authorizedWhenInUse: return true
                case .notDetermined: return false
                case .restricted, .denied:
                    throw LocationError.notAuthorized
                }
            }
            .mapError { LocationError($0) }
            .flatMap { _ in
                Future<Void, LocationError> { promise in
                    self.locationSubject = .init()
                    promise(.success(()))
                    self.beginLocationUpdates(forActivity: activityType, withAccuracy: accuracy)
                }
            }
            .flatMap { _ in
                self.locationSubject
            }
            .handleEvents(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    Self.logger.error("BeginPositioning Completion", metadata: ["localizedDescription": .string(error.localizedDescription)])
                }
            }, receiveCancel: {
                self.endLocationUpdates()
            })
            .eraseToAnyPublisher()
    }
    
    public func monitorRegion(_ region: Region) -> AnyPublisher<GeoFence, LocationError> {
        geoFenceSubject
            .filter { $0.id == region.id }
            .tryMap { geoFence in
                switch geoFence {
                case .failed(_, let error):
                    throw error
                default:
                    return geoFence
                }
            }
            .mapError { LocationError($0) }
            .handleEvents(receiveSubscription: { [locationManager] _ in
                locationManager.startMonitoring(for: CLCircularRegion(region))
            }, receiveCompletion: { [locationManager] _ in
                locationManager.stopMonitoring(for: CLCircularRegion(region))
            }, receiveCancel: { [locationManager] in
                locationManager.stopMonitoring(for: CLCircularRegion(region))
            })
            .eraseToAnyPublisher()
    }
}

extension CoreLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let newAuthorization = ManagerAuthorization(status)
        if newAuthorization != authorizationSubject.value {
            authorizationSubject.send(newAuthorization)
        }
    }
    
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        isLocatingSubject.send(true)
    }
    
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        isLocatingSubject.send(false)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecent = locations.last else {
            return
        }
        
        let location = Location(mostRecent)
        locationSubject.send(location)
        locationObservationSubject.send(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.logger.error("DidFailWithError", metadata: ["localizedDescription": .string(error.localizedDescription)])
        
        guard let coreLocationError = error as? CLError else {
            locationSubject.send(completion: .failure(.undefinedError(error)))
            return
        }
        
        switch coreLocationError.code {
        case .denied:
            locationSubject.send(completion: .failure(.notAuthorized))
        default:
            locationSubject.send(completion: .failure(.undefinedError(coreLocationError)))
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Self.logger.info("Entered Region: \(region)")
        
        guard let circularRegion = region as? CLCircularRegion else {
            return
        }
        
        geoFenceSubject.send(.entered(Region(circularRegion)))
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Self.logger.info("Exited Region: \(region)")
        
        guard let circularRegion = region as? CLCircularRegion else {
            return
        }
        
        geoFenceSubject.send(.exited(Region(circularRegion)))
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Self.logger.error("MonitoringDidFail", metadata: ["localizedDescription": .string(error.localizedDescription)])
        
        if let circularRegion = region as? CLCircularRegion {
            geoFenceSubject.send(.failed(Region(circularRegion), .undefinedError(error)))
        }
    }
}
#endif
