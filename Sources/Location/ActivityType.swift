import Foundation

public enum ActivityType: String, Codable {
    /// Positioning for an automobile following a road network.
    case automotiveNavigation
    /// Positioning for transportation that does not or may not adhere to roads.
    case otherNavigation
    /// Positioning in dedicated fitness sessions.
    case fitness
    /// Positioning for activities in the air.
    case airborne
    /// Positioning for activities that are not covered by one of the other activity types.
    case other
}

#if canImport(CoreLocation)
import CoreLocation

public extension ActivityType {
    init(_ activityType: CLActivityType) {
        switch activityType {
        case .automotiveNavigation:
            self = .automotiveNavigation
        case .otherNavigation:
            self = .otherNavigation
        case .fitness:
            self = .fitness
        case .airborne:
            self = .airborne
        default:
            self = .other
        }
    }
}

public extension CLActivityType {
    init(_ activityType: ActivityType) {
        switch activityType {
        case .automotiveNavigation:
            self = .automotiveNavigation
        case .otherNavigation:
            self = .otherNavigation
        case .fitness:
            self = .fitness
        case .airborne:
            self = .airborne
        case .other:
            self = .other
        }
    }
}
#endif
