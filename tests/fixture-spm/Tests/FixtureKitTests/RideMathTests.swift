import Testing
@testable import FixtureKit

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
}

@Suite("milesToMetres")
struct MilesToMetresTests {
    @Test("1 mile is exactly 1609.344 metres")
    func oneMile() throws {
        let result = try #require(milesToMetres(1))
        #expect(abs(result - 1609.344) < 1e-9)
    }

    @Test("negative miles returns nil")
    func negativeInput() {
        #expect(milesToMetres(-0.5) == nil)
    }
}

@Suite("elevationGain")
struct ElevationGainTests {
    @Test("empty and single samples return zero")
    func degenerateInputs() {
        #expect(elevationGain(from: []) == 0)
        #expect(elevationGain(from: [100]) == 0)
    }

    @Test("only upward deltas contribute")
    func mixedProfile() {
        #expect(elevationGain(from: [100, 110, 105, 120]) == 25)
    }

    @Test("monotonic descent gains nothing")
    func descent() {
        #expect(elevationGain(from: [200, 150, 100]) == 0)
    }
}
