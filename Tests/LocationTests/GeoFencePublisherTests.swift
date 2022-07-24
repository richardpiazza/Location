import XCTest
import HarnessXCTest
import Combine
@testable import Location

final class GeoFencePublisherTests: XCTestCase {
    
    let region1 = Region(id: "one", center: .init(latitude: 1.0, longitude: 1.0), radius: 100.0)
    let region2 = Region(id: "two", center: .init(latitude: 2.0, longitude: 2.0), radius: 100.0)
    var subscription1: AnyCancellable?
    var subscription2: AnyCancellable?
    
    var fenceSubject = PassthroughSubject<GeoFence, LocationError>()
    
    /// Test a publisher similar to the `monitorRegion(_:)` to verify behavior.
    ///
    /// The region monitoring should complete only a publisher if it fails with an associated region.
    func testErrorHandling() {
        var subscription1Complete: Bool = false
        var subscription2Complete: Bool = false
        var subscription1Received: Bool = false
        var subscription2Received: Bool = false
        
        subscription1 = monitorRegion(region1)
            .sink(receiveCompletion: { completion in
                print(completion)
                subscription1Complete = true
            }, receiveValue: { value in
                print(value)
                subscription1Received = true
            })
        
        subscription2 = monitorRegion(region2)
            .sink(receiveCompletion: { completion in
                print(completion)
                subscription2Complete = true
            }, receiveValue: { value in
                print(value)
                subscription2Received = true
            })
        
        fenceSubject.send(.entered(region1))
        fenceSubject.send(.failed(region2, .undefinedError(nil)))
        
        delay(for: 1.0)
        
        XCTAssertFalse(subscription1Complete)
        XCTAssertTrue(subscription1Received)
        XCTAssertTrue(subscription2Complete)
        XCTAssertFalse(subscription2Received)
    }
    
    private func monitorRegion(_ region: Region) -> AnyPublisher<GeoFence, LocationError> {
        fenceSubject
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
}
