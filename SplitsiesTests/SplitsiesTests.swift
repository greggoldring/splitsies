import Testing
@testable import Splitsies

struct SplitsiesTests {
    @Test func pressureUnitConversion() {
        let hPa = 1013.25
        #expect(abs(PressureUnit.hPa.convert(fromHPa: hPa) - 1013.25) < 0.001)
        #expect(abs(PressureUnit.inHg.convert(fromHPa: hPa) - 29.921) < 0.01)
        #expect(abs(PressureUnit.mmHg.convert(fromHPa: hPa) - 760.0) < 0.5)
    }
}
