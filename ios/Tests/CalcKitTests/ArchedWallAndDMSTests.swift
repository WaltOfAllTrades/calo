import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

/// Solves the arched wall directly (not yet in the registry), seeded with the spec's defaults.
private func arch(_ values: [String: FieldValue]) -> [String: FunctionResult] {
    let spec = ArchedWall.spec
    var input = spec.defaults(.defaults)
    for (k, v) in values {
        input[k] = v
    }
    return Dictionary(uniqueKeysWithValues: spec.solve(input, .defaults).map { ($0.id, $0) })
}

private func fi(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: $0.displayUnit ?? .feetInches, precision: .sixteenth, locale: en).text }
}

private func deg(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .degrees, precision: .sixteenth, locale: en).text }
}

private func sqin(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .sqIn, precision: .sixteenth, locale: en).text }
}

private func sqft(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .sqFt, precision: .sixteenth, locale: en).text }
}

private func ft(_ f: Int, _ i: Int = 0, _ fr: Fraction = .zero) -> FieldValue {
    .dimension(.feet(f, i, fr))
}

/// Degrees as the display shows them (two decimals).
private func degText(_ degrees: Double) -> String {
    Format.dimension(.degrees(Fraction(approximating: degrees, denominator: 10000) ?? .zero), unit: .degrees,
                     precision: .sixteenth, locale: en).text
}

struct ArchedWallTests {
    @Test("X5: chord 8′ 1″, rise 2′ 10-1/2″, 16 o.c., outside (UG pp. 41–43)")
    func x5() {
        let r = arch(["chord": ft(8, 1), "rise": ft(2, 10, Fraction(1, 2))])
        #expect(deg(r["arcAngle"]) == "141.7°")
        #expect(fi(r["arcLength"]) == "10′ 7″")
        // The UG prints "sq inch" here (features.md marks it sic); the figures are square feet.
        #expect(sqft(r["segment"]) == "16.96327 sq ft")
        #expect(sqft(r["pie"]) == "22.63527 sq ft")
        #expect(sqin(r["segment"]) == "2,442.711 sq in")
        #expect(fi(r["stud1"]) == "2-9/16″")
        #expect(fi(r["stud2"]) == "11-3/16″")
        #expect(fi(r["stud3"]) == "2′ 9-1/8″")
        #expect(r["stud4"] == nil)
        #expect(fi(r["base"]) == "0″")
    }

    @Test("X5 with a 2′ base: every stud grows by the base")
    func x5Base() {
        let r = arch(["chord": ft(8, 1), "rise": ft(2, 10, Fraction(1, 2)), "base": ft(2)])
        #expect(fi(r["stud1"]) == "2′ 2-9/16″")
        #expect(fi(r["stud2"]) == "2′ 11-3/16″")
        #expect(fi(r["stud3"]) == "4′ 9-1/8″")
        #expect(r["stud4"] == nil)
        #expect(fi(r["base"]) == "2′ 0″")
        #expect(deg(r["arcAngle"]) == "141.7°")
    }

    @Test("X6: inside arched wall, chord 15′, rise 5′ (UG p. 44)")
    func x6() {
        let r = arch(["chord": ft(15), "rise": ft(5), "inside": .toggle(true)])
        #expect(deg(r["arcAngle"]) == "134.76°")
        #expect(fi(r["arcLength"]) == "19′ 1-5/16″")
        #expect(sqft(r["segment"]) == "54.19722 sq ft")
        #expect(sqft(r["pie"]) == "77.63472 sq ft")
        #expect(fi(r["radius"]) == "8′ 1-1/2″")
        #expect(fi(r["stud1"]) == "4′ 10-11/16″")
        #expect(fi(r["stud2"]) == "4′ 6-5/8″")
        #expect(fi(r["stud3"]) == "3′ 11-3/8″")
        #expect(fi(r["stud4"]) == "3′ 0-1/16″")
        #expect(fi(r["stud5"]) == "1′ 6-1/4″")
        #expect(r["stud6"] == nil)
    }

    @Test("Guards: a zero rise, chord or spacing gives nothing; the defaults seed spacing, base and inside")
    func guards() {
        #expect(arch(["chord": ft(15), "rise": ft(0)]).isEmpty)
        #expect(arch(["chord": ft(0), "rise": ft(5)]).isEmpty)
        #expect(arch(["chord": ft(15), "rise": ft(5), "spacing": ft(0)]).isEmpty)
        let seeded = ArchedWall.spec.defaults(.defaults)
        #expect(seeded["spacing"] == .dimension(.inches(Fraction(16))))
        #expect(seeded["base"] == .dimension(.inches(.zero)))
        #expect(seeded["inside"] == .toggle(false))
        #expect(ArchedWall.spec.isComplete(seeded) == false)
    }

    @Test("A stud never lands on the chord's end: chord 8′ at 16 o.c. lists two studs, not three")
    func endStudSkipped() {
        let r = arch(["chord": ft(8), "rise": ft(2)])
        #expect(r["stud2"] != nil)
        #expect(r["stud3"] == nil)
    }
}

struct DMSTests {
    @Test("D27: 23°42′39″ reads as 23.71° in every spelling")
    func d27Entry() throws {
        let expected = 23 + 42 / 60.0 + 39 / 3600.0
        let spellings = [
            "23°42'39\"", "23°42′39″", "23 42 39", "23.42.39", "DMS 23.42.39", "23° 42′ 39″", "23°42'39''",
        ]
        for text in spellings {
            let value = try #require(DMS.degrees(fromText: text), "\(text)")
            #expect(abs(value - expected) < 1e-9, "\(text)")
            #expect(degText(value) == "23.71°", "\(text)")
        }
    }

    @Test("D27: 44.29° prints 44°17′24″; 30°89′ carries to 31°29′00″")
    func d27Display() throws {
        #expect(DMS.text(44.29) == "44°17′24″")
        let carried = try #require(DMS.degrees(fromText: "30°89'"))
        #expect(DMS.text(carried) == "31°29′00″")
        #expect(abs(carried - (31 + 29 / 60.0)) < 1e-9)
    }

    @Test("Spellings: bare decimal, minutes alone, trailing number, negatives; junk is nil")
    func spellings() {
        #expect(DMS.degrees(fromText: "23.71") == 23.71)
        #expect(DMS.degrees(fromText: "42'") == 0.7)
        #expect(DMS.degrees(fromText: "23°30") == 23.5)
        #expect(DMS.degrees(fromText: "−23°30'") == -23.5)
        #expect(DMS.degrees(fromText: "-23 30") == -23.5)
        #expect(DMS.degrees(fromText: "") == nil)
        #expect(DMS.degrees(fromText: "abc") == nil)
        #expect(DMS.degrees(fromText: "23°°") == nil)
        #expect(DMS.degrees(fromText: "39\"42'") == nil)
        #expect(DMS.degrees(fromText: "1.2.3.4") == nil)
        #expect(DMS.text(-23.5) == "−23°30′00″")
    }

    @Test("X19: 35 % grade → 19°17′24″ (UG p. 80)")
    func x19() {
        #expect(DMS.text(AngleFormat.degrees(fromGrade: 35)) == "19°17′24″")
    }

    @Test("X20: rise 6′ over a 10′ hypotenuse → 0.6 → 53.13° → 53°07′48″ (UG p. 81)")
    func x20() {
        let degrees = acos(0.6) * 180 / .pi
        #expect(degText(degrees) == "53.13°")
        #expect(DMS.text(degrees) == "53°07′48″")
    }

    @Test("DMS.text matches AngleFormat.dms except for the zero padding")
    func matchesAngleFormat() {
        #expect(DMS.text(23.71) == "23°42′36″")
        #expect(DMS.text(23.71) == AngleFormat.dms(23.71))
        #expect(AngleFormat.dms(acos(0.6) * 180 / .pi) == "53°07′48″")
    }
}
