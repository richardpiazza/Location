import Foundation

public enum GeoFence {
    case entered(Region)
    case exited(Region)
    case failed(Region, LocationError)
}

extension GeoFence: Identifiable {
    public var id: Region.ID {
        switch self {
        case .entered(let region), .exited(let region), .failed(let region, _):
            return region.id
        }
    }
}
