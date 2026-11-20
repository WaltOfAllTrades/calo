import CalcKit
import Foundation
import Testing

private let en = Locale(identifier: "en_US")

/// Helpers: solve by id, read a result as a feet-inch string at 1/16 (the UG's display).
private func solve(_ id: String, _ values: [String: FieldValue],
                   prefs: CalcPreferences = .defaults) -> [String: FunctionResult] {
    let spec = FunctionSpec.named(id)!
    var input = spec.defaults(prefs)
    for (k, v) in values {
        input[k] = v
    }
    return Dictionary(uniqueKeysWithValues: spec.solve(input, prefs).map { ($0.id, $0) })
}

private func fi(_ r: FunctionResult?, _ precision: Precision = .sixteenth) -> String? {
    r.map { Format.dimension($0.value, unit: $0.displayUnit ?? .feetInches, precision: precision, locale: en).text }
}

private func deg(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .degrees, precision: .sixteenth, locale: en).text }
}

private func count(_ r: FunctionResult?) -> String? {
    r.map { Format.scalar($0.value.value, locale: en).text }
}

private func sqft(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .sqFt, precision: .sixteenth, locale: en).text }
}

private func cuyd(_ r: FunctionResult?) -> String? {
    r.map { Format.dimension($0.value, unit: .cuYd, precision: .sixteenth, locale: en).text }
}

private func ft(_ f: Int, _ i: Int = 0, _ fr: Fraction = .zero) -> FieldValue {
    .dimension(.feet(f, i, fr))
}

private func inch(_ v: Fraction) -> FieldValue {
    .dimension(.inches(v))
}

private func degrees(_ v: Double) -> FieldValue {
    .dimension(.degrees(Fraction(approximating: v, denominator: 10000) ?? .zero))
}

struct StairsTests {
    @Test("S1: rise 9′ 11″ (UG p. 72)")
    func s1() {
        let r = solve("stairs", ["rise": ft(9, 11)])
        #expect(count(r["risers"]) == "16")
        #expect(fi(r["riserHeight"]) == "7-7/16″")
        #expect(fi(r["riserOverage"]) == "0″")
        #expect(count(r["treads"]) == "15")
        #expect(fi(r["treadDepth"]) == "10″")
        #expect(fi(r["opening"]) == "10′ 1″")
        #expect(fi(r["stringer"]) == "15′ 6-15/16″")
        #expect(deg(r["incline"]) == "36.64°")
        #expect(fi(r["totalRun"]) == "12′ 6″")
        #expect(r["riserHeight"]?.warning == nil)
    }

    @Test("S2: run 20′ only (UG p. 74)")
    func s2() {
        let r = solve("stairs", ["run": ft(20)])
        #expect(fi(r["riserHeight"]) == "7-1/2″")
        #expect(count(r["risers"]) == "25")
        #expect(count(r["treads"]) == "24")
        #expect(fi(r["opening"]) == "10′ 0″")
        #expect(fi(r["stringer"]) == "25′ 0″")
        #expect(deg(r["incline"]) == "36.87°")
        #expect(fi(r["totalRise"]) == "15′ 7-1/2″")
    }

    @Test("S3: rise 10′ 1″, run 15′ 5″ (UG p. 75), riser over the IRC limit")
    func s3() {
        let r = solve("stairs", ["rise": ft(10, 1), "run": ft(15, 5)])
        #expect(fi(r["riserHeight"]) == "7-9/16″")
        #expect(count(r["risers"]) == "16")
        #expect(fi(r["treadDepth"]) == "12-5/16″")
        #expect(count(r["treads"]) == "15")
        #expect(fi(r["treadOverage"]) == "\u{2212}0-5/16″")
        #expect(fi(r["opening"]) == "12′ 2-1/2″")
        #expect(fi(r["stringer"]) == "18′ 0-3/4″")
        #expect(deg(r["incline"]) == "31.56°")
        #expect(r["riserHeight"]?.warning == nil) // 7-9/16 is under 7-3/4
    }

    @Test("S4: S3 riser-limited at 7-1/2 (UG p. 76)")
    func s4() {
        let r = solve("stairs", ["rise": ft(10, 1), "run": ft(15, 5), "riserLimited": .toggle(true)])
        #expect(fi(r["riserHeight"]) == "7-1/8″")
        #expect(count(r["risers"]) == "17")
        #expect(fi(r["riserOverage"]) == "0-1/8″")
        #expect(fi(r["treadDepth"]) == "11-9/16″")
        #expect(count(r["treads"]) == "16")
        #expect(fi(r["opening"]) == "12′ 2-1/16″")
        #expect(fi(r["stringer"]) == "18′ 1-5/16″")
        #expect(deg(r["incline"]) == "31.64°")
    }

    @Test("S5 (FHB) and S9 (Navy): riser counts from other sources; warnings fire")
    func others() {
        let fhb = solve("stairs", ["rise": inch(Fraction(46)), "riser": inch(Fraction(31, 4))])
        #expect(count(fhb["risers"]) == "6")
        #expect(fi(fhb["riserHeight"]) == "7-11/16″")
        #expect(fi(fhb["totalRun"]) == "4′ 2″")
        let navy = solve("stairs", ["rise": ft(8, 11), "riser": inch(Fraction(7))])
        #expect(count(navy["risers"]) == "15")
        #expect(fi(navy["riserHeight"]) == "7-1/8″")
        let tall = solve("stairs", ["rise": inch(Fraction(80)), "riser": inch(Fraction(8))])
        #expect(tall["riserHeight"]?.warning == .riserOverLimit)
        let shallow = solve("stairs", ["rise": inch(Fraction(70)), "run": inch(Fraction(70))])
        #expect(shallow["treadDepth"]?.warning == .treadUnderMinimum)
        let low = solve("stairs", ["rise": inch(Fraction(70)), "headroom": inch(Fraction(70))])
        #expect(low["opening"]?.warning == .headroomUnderMinimum)
        #expect(solve("stairs", [:]).isEmpty) // E-K17
    }
}

struct RoofTests {
    @Test("R4, R6, R7: common rafter, rise, from pitch and degrees")
    func common() {
        let r4 = solve("roof", ["pitch": .number(Fraction(7)), "span": ft(14, 4)])
        #expect(fi(r4["common"]) == "8′ 3-9/16″")
        #expect(deg(r4["plumb"]) == "30.26°")
        #expect(deg(r4["level"]) == "59.74°")
        let r6 = solve("roof", ["pitch": .number(Fraction(7)), "run": ft(11, 6)])
        #expect(fi(r6["rise"]) == "6′ 8-1/2″")
        let r7 = solve("roof", ["pitch": degrees(30), "run": ft(20, 4)])
        #expect(fi(r7["rise"]) == "11′ 8-7/8″")
        #expect(fi(r7["common"]) == "23′ 5-3/4″")
    }

    @Test("R9: 7/12, run 8′ 5″, 16 o.c. → hip and jacks (UG pp. 60–61)")
    func r9() {
        let r = solve("roof", ["pitch": .number(Fraction(7)), "run": ft(8, 5)])
        #expect(fi(r["common"]) == "9′ 8-15/16″")
        #expect(fi(r["hip"]) == "12′ 10-1/2″")
        #expect(deg(r["hipPlumb"]) == "22.42°")
        #expect(deg(r["hipLevel"]) == "67.58°")
        #expect(deg(r["cheek"]) == "45°")
        #expect(fi(r["jackIncrement"]) == "1′ 6-1/2″")
        #expect(fi(r["jack1"]) == "8′ 2-3/8″")
        #expect(fi(r["jack2"]) == "6′ 7-7/8″")
        #expect(fi(r["jack3"]) == "5′ 1-3/8″")
        #expect(fi(r["jack4"]) == "3′ 6-13/16″")
        #expect(fi(r["jack5"]) == "2′ 0-5/16″")
        #expect(fi(r["jack6"]) == "5-13/16″")
        #expect(fi(r["jack7"]) == "0″")
        #expect(r["jack8"] == nil)
    }

    @Test("R10: 9/12, run 6′ 9″, 18 o.c.")
    func r10() {
        let r = solve("roof", ["pitch": .number(Fraction(9)), "run": ft(6, 9), "spacing": inch(Fraction(18))])
        #expect(fi(r["jackIncrement"]) == "1′ 10-1/2″")
        #expect(fi(r["jack1"]) == "6′ 6-3/4″")
        #expect(fi(r["jack4"]) == "11-1/4″")
        #expect(fi(r["jack5"]) == "0″")
        #expect(deg(r["plumb"]) == "36.87°")
    }

    @Test("R15: roof covering 10/12 over 14 × 11 ft (UG p. 68); R19 6/12 angle")
    func covering() {
        let r = solve("roof", ["pitch": .number(Fraction(10)), "planLength": ft(14), "planWidth": ft(11)])
        #expect(sqft(r["roofArea"]) == "200.4631 sq ft")
        #expect(sqft(r["planArea"]) == "154 sq ft")
        #expect(count(r["squares"])?.hasPrefix("2.0046") == true)
        #expect(count(r["bundles"])?.hasPrefix("6.0138") == true)
        #expect(count(r["sheets"])?.hasPrefix("6.2644") == true)
        let six = solve("roof", ["pitch": .number(Fraction(6)), "run": ft(12)])
        #expect(deg(six["pitchDegrees"]) == "26.57°")
        #expect(fi(six["common"]) == "13′ 5″")
        // E-K19: zero pitch and zero run do not error.
        #expect(fi(solve("roof", ["pitch": .number(.zero), "run": ft(10)])["common"]) == "10′ 0″")
        #expect(fi(solve("roof", ["pitch": .number(Fraction(7)), "run": ft(0)])["common"]) == "0″")
    }
}

struct ConcreteTests {
    @Test("C1 driveway, C4 footing, C2 column (UG pp. 46–50)")
    func ug() {
        let c1 = solve(
            "concrete",
            ["length": ft(36, 3), "width": ft(11, 6), "depth": inch(Fraction(4)), "waste": .int(0)]
        )
        #expect(sqft(c1["area"]) == "416.875 sq ft")
        #expect(cuyd(c1["volume"]) == "5.146605 cu yd")
        let c4 = solve(
            "concrete",
            ["length": ft(232, 6), "width": inch(Fraction(16)), "depth": inch(Fraction(8)), "waste": .int(0)]
        )
        #expect(cuyd(c4["volume"]) == "7.654321 cu yd")
        let c2 = solve("concrete", ["diameter": ft(3, 4, Fraction(1, 2)), "height": ft(11, 6), "waste": .int(0)])
        #expect(cuyd(c2["volume"]) == "3.810408 cu yd")
        let five = solve(
            "concrete",
            ["diameter": ft(3, 4, Fraction(1, 2)), "height": ft(11, 6), "count": .int(5), "waste": .int(0)]
        )
        #expect(cuyd(five["volume"]) == "19.05204 cu yd")
    }

    @Test("C6 slab with 10 % waste, C8 bags round up, E-K21 zero")
    func bags() {
        let c6 = solve("concrete", ["length": ft(10), "width": ft(10), "depth": inch(Fraction(4)), "waste": .int(10)])
        #expect(cuyd(c6["volume"]) == "1.234568 cu yd")
        #expect(cuyd(c6["withWaste"]) == "1.358025 cu yd")
        let c8 = solve(
            "concrete",
            ["length": ft(12), "width": ft(16), "depth": inch(Fraction(4)), "waste": .int(0), "bag": .int(80)]
        )
        #expect(count(c8["bags"]) == "107")
        let zero = solve("concrete", ["length": ft(0), "width": ft(16), "depth": inch(Fraction(4))])
        #expect(count(zero["bags"]) == "0")
        let sixty = solve(
            "concrete",
            ["length": ft(10), "width": ft(10), "depth": inch(Fraction(4)), "waste": .int(10), "bag": .int(60)]
        )
        #expect(count(sixty["bags"]) == "82")
    }
}

struct BoardFeetTests {
    @Test("B1–B4, B9–B11 (UG p. 38; Wood-Mizer)")
    func boardFeet() {
        let b1 = solve("boardFeet", ["thickness": inch(Fraction(2)), "width": inch(Fraction(4)), "length": ft(14)])
        #expect(count(b1["boardFeet"]) == "9.333333")
        let b2 = solve("boardFeet", ["thickness": inch(Fraction(2)), "width": inch(Fraction(10)), "length": ft(16)])
        #expect(count(b2["boardFeet"]) == "26.66667")
        let b3 = solve("boardFeet", ["thickness": inch(Fraction(2)), "width": inch(Fraction(12)), "length": ft(18)])
        #expect(count(b3["boardFeet"]) == "36")
        let b4 = solve(
            "boardFeet",
            [
                "thickness": inch(Fraction(1)),
                "width": inch(Fraction(12)),
                "length": ft(72),
                "pricePerMbm": .number(Fraction(250)),
            ]
        )
        #expect(b4["cost"]?.value.value == Fraction(18))
        let b9 = solve(
            "boardFeet",
            ["thickness": inch(Fraction(2)), "width": inch(Fraction(8)), "length": ft(12), "count": .int(84)]
        )
        #expect(count(b9["boardFeet"]) == "1,344")
        let b10 = solve("boardFeet", ["thickness": inch(Fraction(5, 4)), "width": inch(Fraction(6)), "length": ft(14)])
        #expect(count(b10["boardFeet"]) == "8.75")
        let b11 = solve(
            "boardFeet",
            ["thickness": inch(Fraction(1)), "width": inch(Fraction(31, 4)), "length": inch(Fraction(63))]
        )
        #expect(count(b11["boardFeet"]) == "3.390625")
    }
}

struct SquareUpTests {
    @Test("A3, A8, A9")
    func squareUp() {
        let a3 = solve("squareUp", ["rise": ft(20, 6), "run": ft(25, 6)])
        #expect(sqft(a3["area"]) == "522.75 sq ft")
        #expect(fi(a3["diagonal"]) == "32′ 8-5/8″")
        #expect(fi(a3["perimeter"]) == "92′ 0″")
        let a8 = solve("squareUp", ["rise": ft(45, 6), "run": ft(23, 8)])
        #expect(fi(a8["diagonal"]) == "51′ 3-7/16″")
        let a9 = solve("squareUp", ["rise": ft(9), "run": ft(12)])
        #expect(fi(a9["diagonal"]) == "15′ 0″")
        #expect(fi(a9["pitch"]) == "9″")
        #expect(deg(a9["angle"]) == "36.87°")
        let fromDiag = solve("squareUp", ["run": ft(12), "diagonal": ft(15)])
        #expect(fi(fromDiag["rise"]) == "9′ 0″")
        #expect(solve("squareUp", ["run": ft(12)]).isEmpty)
    }
}

struct CircleTests {
    @Test("X1–X4 (UG pp. 39–40)")
    func circles() throws {
        let x1 = solve("circle", ["diameter": inch(Fraction(11))])
        #expect(try Format.dimension(#require(x1["area"]?.value), unit: .sqIn, precision: .sixteenth, locale: en)
            .text == "95.03318 sq in")
        #expect(fi(x1["circumference"]) == "2′ 10-9/16″")
        let x2 = solve("circle", ["diameter": ft(5), "arcAngle": degrees(85)])
        #expect(fi(x2["arcLength"]) == "3′ 8-1/2″")
        let x3 = solve("circle", ["chord": ft(3, 6), "rise": ft(1, 3)])
        #expect(fi(x3["radius"]) == "1′ 10-3/16″")
        #expect(deg(x3["arcAngle"]) == "142.15°")
        #expect(fi(x3["arcLength"]) == "4′ 7-1/16″")
        let x4 = solve("circle", ["diameter": ft(5), "arcLength": ft(3, 3)])
        #expect(deg(x4["arcAngle"]) == "74.48°")
        #expect(fi(x4["chord"]) == "3′ 0-5/16″")
        #expect(sqft(x4["segment"]) == "1.051381 sq ft")
        #expect(sqft(x4["pie"]) == "4.0625 sq ft")
        #expect(fi(x4["rise"]) == "6-1/8″")
    }
}

struct MiterPolygonStudsTests {
    @Test("X8 compound miter: spring 38°, corner 60°")
    func miter() {
        let r = solve("miter", ["spring": degrees(38), "corner": degrees(60)])
        #expect(deg(r["miter"]) == "46.84°")
        #expect(deg(r["bevel"]) == "43.03°")
    }

    @Test("X7 polygon: radius 15′, 6 sides; fewer than 3 sides gives nothing (E-K20)")
    func polygon() {
        let r = solve("polygon", ["radius": ft(15), "sides": .int(6)])
        #expect(deg(r["fullAngle"]) == "120°")
        #expect(deg(r["halfAngle"]) == "60°")
        #expect(fi(r["side"]) == "15′ 0″")
        #expect(fi(r["perimeter"]) == "90′ 0″")
        #expect(sqft(r["area"]) == "584.5671 sq ft")
        #expect(solve("polygon", ["radius": ft(15), "sides": .int(2)]).isEmpty)
    }

    @Test("X17 studs: 18′ 7-1/2″ at 16 o.c. → 15")
    func studs() {
        #expect(count(solve("studs", ["length": ft(18, 7, Fraction(1, 2))])["studs"]) == "15")
    }

    @Test("the registry has nine functions with unique ids and required fields detected")
    func registry() throws {
        #expect(FunctionSpec.registry.count == 9)
        #expect(Set(FunctionSpec.registry.map(\.id)).count == 9)
        let stairs = try #require(FunctionSpec.named("stairs"))
        #expect(stairs.isComplete(stairs.defaults(.defaults)))
        let board = try #require(FunctionSpec.named("boardFeet"))
        #expect(!board.isComplete(board.defaults(.defaults)))
    }
}
