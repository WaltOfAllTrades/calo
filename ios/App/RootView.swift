import DesignSystem
import SwiftUI

/// The root of the install: the Experiments setting picks which product is on screen (feature C-040).
/// The environments are built once by `CaloApp` and handed in, so the database opens once.
struct RootView: View {
    let calo: CaloEnvironment
    let calc: CalcEnvironment
    let experiments: ExperimentsStore

    var body: some View {
        Group {
            switch experiments.active {
            case .calo: CaloScreen()
            case .calculator: CalculatorScreen()
            }
        }
        .environment(\.calo, calo)
        .environment(\.calc, calc)
        .environment(\.experiments, experiments)
    }
}
