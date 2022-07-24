import Foundation

public enum LocationError: Error {
    /// Location permission not granted.
    case notAuthorized
    case undefinedError(_ error: Error?)
    
    public init(_ error: Error) {
        switch error {
        case let locationError as LocationError:
            self = locationError
        default:
            self = .undefinedError(error)
        }
    }
}
