import Foundation
import Combine
import Harness
import Location

open class EmulatedLocationManager: LocationManager {
    
    /// The success/failure of requesting authorization.
    public enum AuthorizationBehavior: Codable {
        /// Transitions to an authorized state.
        ///
        /// * `authorization` is set to `.authorizedAlways`
        case success
        /// Transitions to a denied/unauthorized state.
        ///
        /// * `authorization` is set to `.denied`
        case failure
    }
    
    public struct Configuration: EnvironmentConfiguration {
        public static let environmentKey: String = "LOCATION_MANAGER_CONFIGURATION"
        
        public var authorization: ManagerAuthorization?
        public var authorizationBehavior: AuthorizationBehavior?
        /// The initial coordinates expressed by the manager.
        public var coordinates: Coordinates?
        /// Coordinate mapping for specific postal addresses.
        public var geoCoding: [PostalAddress: Coordinates]?
        /// A collection of locations that should be replayed when positioning requested.
        public var positioning: [Location]?
        /// The rate at which locations should be emitted in seconds.
        public var positioningRate: Int?
        /// Regions that should be monitored for geofencing.
        public var regions: [Region]?
        
        public init(
            authorization: ManagerAuthorization? = nil,
            authorizationBehavior: AuthorizationBehavior? = nil,
            coordinates: Coordinates? = nil,
            geoCoding: [PostalAddress: Coordinates]? = nil,
            positioning: [Location]? = nil,
            positioningRate: Int? = nil,
            regions: [Region]? = nil
        ) {
            self.authorization = authorization
            self.authorizationBehavior = authorizationBehavior
            self.coordinates = coordinates
            self.geoCoding = geoCoding
            self.positioning = positioning
            self.positioningRate = positioningRate
            self.regions = regions
        }
    }
    
    public let authorizationSubject: CurrentValueSubject<ManagerAuthorization, Never>
    public var authorization: ManagerAuthorization { authorizationSubject.value }
    public var authorizationPublisher: AnyPublisher<ManagerAuthorization, Never> { authorizationSubject.eraseToAnyPublisher() }
    
    public let isLocatingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    public var isLocating: Bool { isLocatingSubject.value }
    public var isLocatingPublisher: AnyPublisher<Bool, Never> { isLocatingSubject.eraseToAnyPublisher() }
    
    public let locationSubject: CurrentValueSubject<Location?, Never>
    public var lastLocation: Location? { locationSubject.value }
    public var locationObservationPublisher: AnyPublisher<Location?, Never> { locationSubject.eraseToAnyPublisher() }
    
    public let geoFenceSubject: PassthroughSubject<GeoFence, LocationError> = .init()
    
    private var regionsContainingLocation: [Region] = []
    private var regionsNotContainingLocation: [Region] = []
    
    internal var authorizationBehavior: AuthorizationBehavior
    internal var geoCoding: [PostalAddress: Coordinates]
    internal var positioning: [Location]
    internal var positioningRate: Int
    
    public init(
        authorization: ManagerAuthorization = .notDetermined,
        authorizationBehavior: AuthorizationBehavior = .failure,
        coordinates: Coordinates? = nil,
        geoCoding: [PostalAddress: Coordinates] = [:],
        positioning: [Location] = [],
        positioningRate: Int = 30,
        regions: [Region] = []
    ) {
        authorizationSubject = .init(authorization)
        self.authorizationBehavior = authorizationBehavior
        self.geoCoding = geoCoding
        self.positioning = positioning
        self.positioningRate = positioningRate
        
        if let coordinates = coordinates {
            let location = Location(coordinates: coordinates)
            locationSubject = .init(location)
            for region in regions {
                if let distance = distance(to: region.coordinates, from: location), distance <= region.radius {
                    regionsContainingLocation.append(region)
                } else {
                    regionsNotContainingLocation.append(region)
                }
            }
        } else {
            locationSubject = .init(nil)
            regionsNotContainingLocation.append(contentsOf: regions)
        }
    }
    
    public init(configuration: Configuration) {
        authorizationSubject = .init(configuration.authorization ?? .notDetermined)
        authorizationBehavior = configuration.authorizationBehavior ?? .failure
        geoCoding = configuration.geoCoding ?? [:]
        positioning = configuration.positioning ?? []
        positioningRate = configuration.positioningRate ?? 30
        
        if let coordinates = configuration.coordinates {
            let location = Location(coordinates: coordinates)
            locationSubject = .init(location)
            for region in (configuration.regions ?? []) {
                if let distance = distance(to: region.coordinates, from: location), distance <= region.radius {
                    regionsContainingLocation.append(region)
                } else {
                    regionsNotContainingLocation.append(region)
                }
            }
        } else {
            locationSubject = .init(nil)
            regionsNotContainingLocation.append(contentsOf: (configuration.regions ?? []))
        }
    }
    
    public func requestAuthorization() {
        switch authorizationBehavior {
        case .success:
            guard authorization != .authorizedAlways else {
                return
            }
            
            authorizationSubject.send(.authorizedAlways)
        case .failure:
            guard authorization != .denied else {
                return
            }
            
            authorizationSubject.send(.denied)
        }
    }
    
    public func coordinates(for postalAddress: PostalAddress) async -> Coordinates? {
        geoCoding[postalAddress]
    }
    
    public func distance(to coordinates: Coordinates, from location: Location) -> Double? {
        // Estimated using 'Haversin' formula.
        func haversin(_ angle: Double) -> Double {
            (1 - cos(angle)) / 2
        }
        
        func ahaversin(_ angle: Double) -> Double {
            2 * asin(sqrt(angle))
        }
        
        func degreeToRadian(_ angle: Double) -> Double {
            (angle / 360) * 2 * .pi
        }
        
        let radius = 6367444.7 // Earths Radius in meters
        let lat1 = degreeToRadian(location.coordinates.latitude)
        let long1 = degreeToRadian(location.coordinates.longitude)
        let lat2 = degreeToRadian(coordinates.latitude)
        let long2 = degreeToRadian(coordinates.longitude)
        
        return radius * ahaversin(haversin(lat2 - lat1) + cos(lat1) * cos(lat2) * haversin(long2 - long1))
    }
    
    public func currentLocation(withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError> {
        beginPositioning(forActivity: .other, withAccuracy: accuracy)
            .first()
            .eraseToAnyPublisher()
    }
    
    public func beginPositioning(forActivity activityType: ActivityType, withAccuracy accuracy: Accuracy) -> AnyPublisher<Location, LocationError> {
        if positioning.isEmpty {
            return locationSubject
                .filter { $0 != nil }
                .map { $0! }
                .setFailureType(to: LocationError.self)
                .handleEvents { [weak self] _ in
                    self?.isLocatingSubject.send(true)
                } receiveCancel: { [weak self] in
                    self?.isLocatingSubject.send(false)
                }
                .eraseToAnyPublisher()
        } else {
            let delay = Timer.publish(every: TimeInterval(positioningRate), on: .main, in: .default).autoconnect()
            let sequence = Publishers.Sequence(sequence: positioning).setFailureType(to: Never.self)
            
            return Publishers.Zip(delay, sequence)
                .map { $0.1 }
                .setFailureType(to: LocationError.self)
                .handleEvents { [weak self] _ in
                    self?.isLocatingSubject.send(true)
                } receiveOutput: { [weak self] location in
                    self?.transitionToLocation(location)
                } receiveCancel: { [weak self] in
                    self?.isLocatingSubject.send(false)
                }
                .eraseToAnyPublisher()
        }
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
            .eraseToAnyPublisher()
    }
    
    /// Handles Region Monitoring
    ///
    /// As the location changes, regions should be entered/exited.
    private func transitionToLocation(_ location: Location) {
        locationSubject.send(location)
        
        let regionsEntered = regionsNotContainingLocation.filter { region in
            if let distance = distance(to: region.coordinates, from: location), distance <= region.radius {
                return true
            } else {
                return false
            }
        }
        
        regionsEntered.forEach {
            geoFenceSubject.send(.entered($0))
        }
        
        let regionsExited = regionsContainingLocation.filter { region in
            if let distance = distance(to: region.coordinates, from: location), distance > region.radius {
                return true
            } else {
                return false
            }
        }
        
        regionsExited.forEach {
            geoFenceSubject.send(.exited($0))
        }
        
        regionsNotContainingLocation.removeAll { regionsEntered.map(\.id).contains($0.id) }
        regionsContainingLocation.removeAll { regionsExited.map(\.id).contains($0.id) }
        
        regionsNotContainingLocation.append(contentsOf: regionsExited)
        regionsContainingLocation.append(contentsOf: regionsEntered)
    }
}
