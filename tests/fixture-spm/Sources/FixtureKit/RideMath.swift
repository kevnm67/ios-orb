import Foundation

// MARK: - Distance Conversion

/// Convert metres to miles.
/// - Parameter metres: Distance in metres. Must be ≥ 0.
/// - Returns: Distance in miles, or nil if input is negative.
public func metresToMiles(_ metres: Double) -> Double? {
    guard metres >= 0 else { return nil }
    return metres / 1609.344
}

/// Convert miles to metres.
/// - Parameter miles: Distance in miles. Must be ≥ 0.
/// - Returns: Distance in metres, or nil if input is negative.
public func milesToMetres(_ miles: Double) -> Double? {
    guard miles >= 0 else { return nil }
    return miles * 1609.344
}

// MARK: - Elevation

/// Total elevation gain from an array of altitude samples (metres).
/// Only upward changes contribute; negative deltas are ignored.
/// - Parameter samples: Ordered altitude readings in metres.
/// - Returns: Total elevation gain in metres (≥ 0). Returns 0 for empty/single-element arrays.
public func elevationGain(from samples: [Double]) -> Double {
    guard samples.count > 1 else { return 0 }
    var gain = 0.0
    for index in 1 ..< samples.count {
        let delta = samples[index] - samples[index - 1]
        if delta > 0 {
            gain += delta
        }
    }
    return gain
}
