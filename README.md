# Location
A swift library for interacting with location services.

<p>
    <img src="https://github.com/richardpiazza/Location/workflows/Swift/badge.svg?branch=main" />
</p>

_Note: The current implementation only works on **Apple** platforms, due to its heavy reliance on the **Combine** framework._

## Installation

**Location** is distributed using the [Swift Package Manager](https://swift.org/package-manager). To install it into a 
project, add it as a  dependency within your `Package.swift` manifest:

```swift
let package = Package(
    ...
    // Package Dependencies
    dependencies: [
        .package(url: "https://github.com/RichardPiazza/Location.git", .upToNextMajor(from: "0.1.0"))
    ],
    ...
    // Target Dependencies
    dependencies: [
        .product(name: "Location", package: "Location")
    ]
)
```

## Targets

### Location

Provides abstracted protocols and classes for interacting with Location services.
On Apple platforms this is the `CoreLocation` framework.

### LocationEmulation

Classes that implement the protocols with basic functionality for emulating behavior (simulator).
