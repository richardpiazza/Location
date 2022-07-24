import Foundation
import Location

public extension Coordinates {
    static let broadwayPizza: Coordinates = Coordinates(latitude: 45.030975, longitude: -93.335811)
    static let wickedWart: Coordinates = Coordinates(latitude: 45.030962476480134, longitude: -93.33913594185849)
    static let travail: Coordinates = Coordinates(latitude: 45.03035240773687, longitude: -93.33839261024926)
    static let dairyQueen: Coordinates = Coordinates(latitude: 45.027995338723564, longitude: -93.33552387917561)
    
    static let origin: Coordinates = Coordinates(latitude: 45.035160338664646, longitude: -93.32365406531093)
}

public extension Array where Element == Coordinates {
    static let deliveryRoute: [Coordinates] = [
        Coordinates(latitude: 45.03258494217732, longitude: -93.33743029155595),
        Coordinates(latitude: 45.03214612950932, longitude: -93.33692024548058),
        Coordinates(latitude: 45.031221477516134, longitude: -93.33585025751822),
        Coordinates(latitude: 45.03053581488426, longitude: -93.33613300045418),
        Coordinates(latitude: 45.03126457601693, longitude: -93.33705330099677),
        Coordinates(latitude: 45.032208817234036, longitude: -93.33820644865693),
        Coordinates(latitude: 45.031813099787115, longitude: -93.33909902928876),
        Coordinates(latitude: 45.0311901331028, longitude: -93.34009694554682),
        Coordinates(latitude: 45.030822599487685, longitude: -93.33948864925097),
        Coordinates(latitude: 45.03045294811933, longitude: -93.33945207263186),
        Coordinates(latitude: 45.03013678217262, longitude: -93.3386526317154),
        Coordinates(latitude: 45.02974634450012, longitude: -93.33884668886894),
        Coordinates(latitude: 45.029137206993504, longitude: -93.33831696527551),
        Coordinates(latitude: 45.02958324948795, longitude: -93.33742185480071),
        Coordinates(latitude: 45.0291483272025, longitude: -93.33684842462317),
        Coordinates(latitude: 45.02863432387644, longitude: -93.3362173017707),
        Coordinates(latitude: 45.028017488699724, longitude: -93.3357065313873),
    ]
}
