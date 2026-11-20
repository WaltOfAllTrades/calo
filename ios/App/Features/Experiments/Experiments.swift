import DesignSystem
import Foundation
import SwiftUI

/// The one install's two products (GOAL: "a Settings → Experiments switch picks which app the
/// install opens as"). Stored apart from either product's settings so each reads only its own.
enum Product: String, Codable, CaseIterable, Identifiable, Sendable {
    case calo, calculator

    var id: String {
        rawValue
    }

    /// Products that have a screen to open.
    static let available: [Product] = [.calo, .calculator]
}

/// Calo's keypad: the web app's bevelled keys (Walt's design, the default) or system glass keys.
enum CaloKeyStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case original, glass
    var id: String {
        rawValue
    }
}

struct Experiments: Codable, Equatable, Sendable {
    var openAs: Product = .calo
    var caloKeys: CaloKeyStyle = .original

    private enum CodingKeys: String, CodingKey {
        case openAs, caloKeys
    }

    init(openAs: Product = .calo, caloKeys: CaloKeyStyle = .original) {
        self.openAs = openAs
        self.caloKeys = caloKeys
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        openAs = (try? container.decodeIfPresent(Product.self, forKey: .openAs)) ?? .calo
        caloKeys = (try? container.decodeIfPresent(CaloKeyStyle.self, forKey: .caloKeys)) ?? .original
    }
}

/// JSON in UserDefaults under one key; `-calo.openAs <product>` overrides for tests.
@Observable
final class ExperimentsStore {
    static let key = "calo.experiments"
    private let defaults: UserDefaults
    private(set) var current: Experiments
    /// The product on screen. A new choice is stored at once but takes effect when the settings sheet
    /// that holds the picker has closed (`activate()`), so the presenting screen is not torn down mid-sheet.
    private(set) var active: Product

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults
        var loaded = Experiments()
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(Experiments.self, from: data) {
            loaded = decoded
        }
        if let index = arguments.firstIndex(of: "-calo.openAs"), index + 1 < arguments.count,
           let forced = Product(rawValue: arguments[index + 1]) {
            loaded.openAs = forced
        }
        current = loaded
        active = Product.available.contains(loaded.openAs) ? loaded.openAs : .calo
    }

    /// Applies the stored choice to the screen.
    func activate() {
        active = openAs
    }

    func save(_ experiments: Experiments) {
        current = experiments
        if let data = try? JSONEncoder().encode(experiments) {
            defaults.set(data, forKey: Self.key)
        }
    }

    /// The product the root should show: a stored choice that has no screen yet falls back to Calo.
    var openAs: Product {
        Product.available.contains(current.openAs) ? current.openAs : .calo
    }
}

extension EnvironmentValues {
    @Entry var experiments = ExperimentsStore()
}

/// The shared Experiments screen, reachable from both products' settings (feature C-040).
struct ExperimentsScreen: View {
    @Environment(\.experiments) private var store

    var body: some View {
        List {
            Section {
                Picker(L10n.shared.experimentsOpenAs, selection: binding) {
                    ForEach(Product.available) { product in
                        Text(title(for: product)).tag(product)
                    }
                }
                .pickerStyle(.inline)
                .accessibilityIdentifier("shared.experiments.openAs")
            } footer: {
                Text(L10n.shared.experimentsOpenAsFooter)
            }
            Section {
                Picker(L10n.shared.experimentsCaloKeys, selection: keysBinding) {
                    Text(L10n.shared.caloKeysOriginal).tag(CaloKeyStyle.original)
                    Text(L10n.shared.caloKeysGlass).tag(CaloKeyStyle.glass)
                }
                .pickerStyle(.inline)
                .accessibilityIdentifier("shared.experiments.caloKeys")
            } footer: {
                Text(L10n.shared.experimentsCaloKeysFooter)
            }
        }
        .navigationTitle(Text(L10n.shared.experimentsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var keysBinding: Binding<CaloKeyStyle> {
        Binding(
            get: { store.current.caloKeys },
            set: { style in
                var next = store.current
                next.caloKeys = style
                store.save(next)
            }
        )
    }

    private var binding: Binding<Product> {
        Binding(
            get: { store.openAs },
            set: { product in
                var next = store.current
                next.openAs = product
                store.save(next)
            }
        )
    }

    private func title(for product: Product) -> LocalizedStringResource {
        switch product {
        case .calo: L10n.shared.productCalo
        case .calculator: L10n.shared.productCalculator
        }
    }
}
