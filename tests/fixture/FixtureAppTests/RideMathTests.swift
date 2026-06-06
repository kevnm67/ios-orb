import Testing
@testable import FixtureApp

// MARK: - Distance Conversion Tests

@Suite("metresToMiles")
struct MetresToMilesTests {
    @Test("zero metres is zero miles")
    func zeroMetres() {
        #expect(metresToMiles(0) == 0)
    }

    @Test("1609.344 metres is exactly 1 mile")
    func oneMile() throws {
        let result = try #require(metresToMiles(1609.344))
        #expect(abs(result - 1.0) < 1e-9)
    }

    @Test("negative metres returns nil")
    func negativeInput() {
        #expect(metresToMiles(-1) == nil)
    }

    @Test("round-trip: miles -> metres -> miles")
    func roundTrip() throws {
        let originalMiles = 5.0
        let metres = try #require(milesToMetres(originalMiles))
        let backToMiles = try #require(metresToMiles(metres))
        #expect(abs(backToMiles - originalMiles) < 1e-9)
    }
}

@Suite("milesToMetres")
struct MilesToMetresTests {
    @Test("zero miles is zero metres")
    func zeroMiles() {
        #expect(milesToMetres(0) == 0)
    }

    @Test("1 mile is 1609.344 metres")
    func oneMile() throws {
        let result = try #require(milesToMetres(1.0))
        #expect(abs(result - 1609.344) < 1e-6)
    }

    @Test("negative miles returns nil")
    func negativeInput() {
        #expect(milesToMetres(-0.1) == nil)
    }
}

// MARK: - Pace Tests

@Suite("pace(distanceMetres:durationSeconds:)")
struct PaceTests {
    @Test("positive distance and duration produces correct pace")
    func normalCase() throws {
        // 1 mile (1609.344 m) in 600 s = 10 min/mile
        let result = try #require(pace(distanceMetres: 1609.344, durationSeconds: 600))
        #expect(abs(result - 10.0) < 1e-6)
    }

    @Test("zero distance returns nil")
    func zeroDistance() {
        #expect(pace(distanceMetres: 0, durationSeconds: 600) == nil)
    }

    @Test("zero duration returns nil")
    func zeroDuration() {
        #expect(pace(distanceMetres: 1609.344, durationSeconds: 0) == nil)
    }

    @Test("negative distance returns nil")
    func negativeDistance() {
        #expect(pace(distanceMetres: -100, durationSeconds: 600) == nil)
    }

    @Test("negative duration returns nil")
    func negativeDuration() {
        #expect(pace(distanceMetres: 1609.344, durationSeconds: -1) == nil)
    }
}

// MARK: - Elevation Gain Tests

@Suite("elevationGain(from:)")
struct ElevationGainTests {
    @Test("empty array returns 0")
    func emptyArray() {
        #expect(elevationGain(from: []) == 0)
    }

    @Test("single element returns 0")
    func singleElement() {
        #expect(elevationGain(from: [100.0]) == 0)
    }

    @Test("strictly ascending samples sum all deltas")
    func ascending() {
        let gain = elevationGain(from: [0, 10, 20, 30])
        #expect(gain == 30)
    }

    @Test("strictly descending samples produce 0 gain")
    func descending() {
        let gain = elevationGain(from: [300, 200, 100])
        #expect(gain == 0)
    }

    @Test("mixed up-down correctly accumulates only ups")
    func mixedProfile() {
        // +50, -20, +30 -> gain = 80
        let gain = elevationGain(from: [0, 50, 30, 60])
        #expect(gain == 80)
    }

    @Test("plateau (same altitude) contributes nothing")
    func plateau() {
        let gain = elevationGain(from: [100, 100, 100])
        #expect(gain == 0)
    }
}

// MARK: - Heart Rate Validation Tests

@Suite("isValidHeartRate(_:)")
struct HeartRateValidationTests {
    @Test("lower boundary 30 bpm is valid")
    func lowerBound() {
        #expect(isValidHeartRate(30))
    }

    @Test("upper boundary 250 bpm is valid")
    func upperBound() {
        #expect(isValidHeartRate(250))
    }

    @Test("29 bpm is invalid")
    func belowLower() {
        #expect(!isValidHeartRate(29))
    }

    @Test("251 bpm is invalid")
    func aboveUpper() {
        #expect(!isValidHeartRate(251))
    }

    @Test("typical resting heart rate 60 bpm is valid")
    func typicalResting() {
        #expect(isValidHeartRate(60))
    }

    @Test("zero bpm is invalid")
    func zeroBpm() {
        #expect(!isValidHeartRate(0))
    }
}

// MARK: - Duration Formatting Tests

@Suite("formatDuration(_:)")
struct FormatDurationTests {
    @Test("zero seconds formats as 00:00")
    func zeroSeconds() {
        #expect(formatDuration(0) == "00:00")
    }

    @Test("negative input is clamped to 00:00")
    func negativeInput() {
        #expect(formatDuration(-5) == "00:00")
    }

    @Test("59 seconds formats as 00:59")
    func underOneMinute() {
        #expect(formatDuration(59) == "00:59")
    }

    @Test("60 seconds formats as 01:00")
    func exactlyOneMinute() {
        #expect(formatDuration(60) == "01:00")
    }

    @Test("3661 seconds formats as 1:01:01")
    func oneHourOneMinuteOneSecond() {
        #expect(formatDuration(3661) == "1:01:01")
    }

    @Test("exactly one hour formats as 1:00:00")
    func exactlyOneHour() {
        #expect(formatDuration(3600) == "1:00:00")
    }

    @Test("90 minutes formats correctly without hours prefix")
    func ninetyMinutes() {
        // 5400 s = 1h 30m -> should show hours
        #expect(formatDuration(5400) == "1:30:00")
    }
}
