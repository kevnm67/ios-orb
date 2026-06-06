import Foundation

// MARK: - Distance Conversion

/// Convert metres to miles.
/// - Parameter metres: Distance in metres. Must be ≥ 0.
/// - Returns: Distance in miles, or nil if input is negative.
func metresToMiles(_ metres: Double) -> Double? {
    guard metres >= 0 else { return nil }
    return metres / 1609.344
}

/// Convert miles to metres.
/// - Parameter miles: Distance in miles. Must be ≥ 0.
/// - Returns: Distance in metres, or nil if input is negative.
func milesToMetres(_ miles: Double) -> Double? {
    guard miles >= 0 else { return nil }
    return miles * 1609.344
}

// MARK: - Pace Calculation

/// Calculate pace in minutes-per-mile given a distance (metres) and duration (seconds).
/// - Parameters:
///   - distanceMetres: Total distance in metres. Must be > 0.
///   - durationSeconds: Total elapsed time in seconds. Must be > 0.
/// - Returns: Pace in minutes/mile, or nil for invalid inputs.
func pace(distanceMetres: Double, durationSeconds: Double) -> Double? {
    guard distanceMetres > 0, durationSeconds > 0 else { return nil }
    let miles = distanceMetres / 1609.344
    return (durationSeconds / 60.0) / miles
}

// MARK: - Elevation

/// Total elevation gain from an array of altitude samples (metres).
/// Only upward changes contribute; negative deltas are ignored.
/// - Parameter samples: Ordered altitude readings in metres.
/// - Returns: Total elevation gain in metres (≥ 0). Returns 0 for empty/single-element arrays.
func elevationGain(from samples: [Double]) -> Double {
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

// MARK: - Input Validation

/// Validates that a heart-rate BPM value is physiologically plausible.
/// - Parameter bpm: Heart rate in beats per minute.
/// - Returns: `true` when 30 ≤ bpm ≤ 250.
func isValidHeartRate(_ bpm: Int) -> Bool {
    bpm >= 30 && bpm <= 250
}

/// Format a duration in seconds to a human-readable "H:MM:SS" or "MM:SS" string.
/// - Parameter seconds: Total elapsed seconds. Clamped to 0 if negative.
/// - Returns: Formatted duration string.
func formatDuration(_ seconds: Int) -> String {
    let clamped = max(0, seconds)
    let hours = clamped / 3600
    let minutes = (clamped % 3600) / 60
    let secs = clamped % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}
