import Foundation

/// Every user-facing string, by key (spec/calo/copy.md, spec/calculator/copy.md). Views never hold a
/// literal (code-standards 9). Keys are the catalog's; the values live in `Localizable.xcstrings`.
enum L10n {
    enum calo {
        static let brand = LocalizedStringResource("calo.brand")
        static let intentAdd = LocalizedStringResource("calo.intent.add")
        static let intentSubtract = LocalizedStringResource("calo.intent.subtract")
        static let dashLogged = LocalizedStringResource("calo.dash.logged")
        static let dashRemaining = LocalizedStringResource("calo.dash.remaining")
        static let errorBusy = LocalizedStringResource("calo.error.busy")
        static let errorFailed = LocalizedStringResource("calo.error.failed")
        static let fieldName = LocalizedStringResource("calo.field.name")
        static let fieldDetails = LocalizedStringResource("calo.field.details")
        static let keyClear = LocalizedStringResource("calo.key.clear")
        static let settingsTodayLog = LocalizedStringResource("calo.settings.todayLog")
        static let settingsAbout = LocalizedStringResource("calo.settings.about")
        static let settingsShowName = LocalizedStringResource("calo.settings.showName")
        static let settingsShowDetails = LocalizedStringResource("calo.settings.showDetails")
        static let settingsTarget = LocalizedStringResource("calo.settings.target")
        static let settingsExperiments = LocalizedStringResource("calo.settings.experiments")
        static let settingsClear = LocalizedStringResource("calo.settings.clear")
        static let settingsClearConfirm = LocalizedStringResource("calo.settings.clear.confirm")
        static let settingsClearDone = LocalizedStringResource("calo.settings.clear.done")
        static let settingsDone = LocalizedStringResource("calo.settings.done")
        static let logTitle = LocalizedStringResource("calo.log.title")
        static let logSubtitle = LocalizedStringResource("calo.log.subtitle")
        static let logEmpty = LocalizedStringResource("calo.log.empty")
        static let logColumnTime = LocalizedStringResource("calo.log.column.time")
        static let logColumnCalories = LocalizedStringResource("calo.log.column.calories")
        static let logColumnName = LocalizedStringResource("calo.log.column.name")
        static let logColumnDetails = LocalizedStringResource("calo.log.column.details")
        static let logDelete = LocalizedStringResource("calo.log.delete")
        static let editTitle = LocalizedStringResource("calo.edit.title")
        static let editCalories = LocalizedStringResource("calo.edit.calories")
        static let editName = LocalizedStringResource("calo.edit.name")
        static let editDetails = LocalizedStringResource("calo.edit.details")
        static let editCancel = LocalizedStringResource("calo.edit.cancel")
        static let editSave = LocalizedStringResource("calo.edit.save")
        static let aboutQuote = LocalizedStringResource("calo.about.quote")
        static let aboutTagline = LocalizedStringResource("calo.about.tagline")
        static let aboutBody = LocalizedStringResource("calo.about.body")
        static let a11yKeyAdd = LocalizedStringResource("calo.a11y.key.add")
        static let a11yKeySubtract = LocalizedStringResource("calo.a11y.key.subtract")
        static let a11yKeyBackspace = LocalizedStringResource("calo.a11y.key.backspace")
        static let a11yKeyEnter = LocalizedStringResource("calo.a11y.key.enter")
        static let a11yKeyClear = LocalizedStringResource("calo.a11y.key.clear")
        static let a11ySettings = LocalizedStringResource("calo.a11y.settings")
        static let a11yBack = LocalizedStringResource("calo.a11y.back")
        static let a11yBuffer = LocalizedStringResource("calo.a11y.buffer")

        static func a11yDashLogged(_ value: Int) -> String {
            String(localized: "calo.a11y.dash.logged \(value.formatted())")
        }

        static func a11yDashRemaining(_ value: Int) -> String {
            String(localized: "calo.a11y.dash.remaining \(value.formatted())")
        }
    }

    enum shared {
        static let experimentsTitle = LocalizedStringResource("shared.experiments.title")
        static let experimentsOpenAs = LocalizedStringResource("shared.experiments.openAs")
        static let experimentsOpenAsFooter = LocalizedStringResource("shared.experiments.openAs.footer")
        static let productCalo = LocalizedStringResource("shared.product.calo")
        static let productCalculator = LocalizedStringResource("shared.product.calculator")
        static let experimentsCaloKeys = LocalizedStringResource("shared.experiments.caloKeys")
        static let experimentsCaloKeysFooter = LocalizedStringResource("shared.experiments.caloKeys.footer")
        static let caloKeysOriginal = LocalizedStringResource("shared.caloKeys.original")
        static let caloKeysGlass = LocalizedStringResource("shared.caloKeys.glass")
    }
}
