import Foundation

/// Used to specify the accuracy level desired.
///
/// The location service will try its best to achieve your desired accuracy. However, it is not guaranteed.
/// To optimize power performance, be sure to specify an appropriate accuracy for your usage scenario
/// (eg, use a large accuracy value when only a coarse location is needed).
public enum Accuracy: String, Codable {
    case bestForNavigation
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
    case reduced
}

#if canImport(CoreLocation)
import CoreLocation

public extension Accuracy {
    init(_ accuracy: CLLocationAccuracy) {
        switch accuracy {
        case kCLLocationAccuracyBestForNavigation:
            self = .bestForNavigation
        case kCLLocationAccuracyBest:
            self = .best
        case kCLLocationAccuracyNearestTenMeters:
            self = .nearestTenMeters
        case kCLLocationAccuracyHundredMeters:
            self = .hundredMeters
        case kCLLocationAccuracyKilometer:
            self = .kilometer
        case kCLLocationAccuracyThreeKilometers:
            self = .threeKilometers
        default:
            self = .reduced
        }
    }
}

public extension CLLocationAccuracy {
    init(_ accuracy: Accuracy) {
        switch accuracy {
        case .bestForNavigation:
            self = kCLLocationAccuracyBestForNavigation
        case .best:
            self = kCLLocationAccuracyBest
        case .nearestTenMeters:
            self = kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:
            self = kCLLocationAccuracyHundredMeters
        case .kilometer:
            self = kCLLocationAccuracyKilometer
        case .threeKilometers:
            self = kCLLocationAccuracyThreeKilometers
        case .reduced:
            self = kCLLocationAccuracyReduced
        }
    }
}
#endif
