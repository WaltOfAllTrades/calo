import SwiftUI

/// Entry point. One install hosts two products; `RootView` picks which one opens from the
/// Experiments setting (spec/calo/SPEC.md → Experiments, feature C-040). The environments live here
/// so they are created exactly once per process.
@main
struct CaloApp: App {
    private let calo = CaloEnvironment.fromProcess()
    private let calc = CalcEnvironment.fromProcess()
    private let experiments = ExperimentsStore()

    var body: some Scene {
        WindowGroup {
            RootView(calo: calo, calc: calc, experiments: experiments)
        }
    }
}
