@testable import Calo
import Foundation
import Testing

/// Every key `L10n` names resolves in the catalog (architecture §6: one strings catalog, no literals).
/// A key that falls through shows itself on screen, which this catches before a device does.
struct StringsCatalogTests {
    private static let resources: [LocalizedStringResource] = [
        L10n.calo.brand, L10n.calo.intentAdd, L10n.calo.intentSubtract, L10n.calo.dashLogged, L10n.calo.dashRemaining,
        L10n.calo.errorBusy, L10n.calo.errorFailed, L10n.calo.fieldName, L10n.calo.fieldDetails, L10n.calo.keyClear,
        L10n.calo.settingsTodayLog, L10n.calo.settingsAbout, L10n.calo.settingsShowName, L10n.calo.settingsShowDetails,
        L10n.calo.settingsTarget, L10n.calo.settingsExperiments, L10n.calo.settingsClear,
        L10n.calo.settingsClearConfirm,
        L10n.calo.settingsClearDone, L10n.calo.settingsDone, L10n.calo.logTitle, L10n.calo.logSubtitle,
        L10n.calo.logEmpty,
        L10n.calo.logColumnTime, L10n.calo.logColumnCalories, L10n.calo.logColumnName, L10n.calo.logColumnDetails,
        L10n.calo.logDelete, L10n.calo.editTitle, L10n.calo.editCalories, L10n.calo.editName, L10n.calo.editDetails,
        L10n.calo.editCancel, L10n.calo.editSave, L10n.calo.aboutQuote, L10n.calo.aboutTagline, L10n.calo.aboutBody,
        L10n.calo.a11yKeyAdd, L10n.calo.a11yKeySubtract, L10n.calo.a11yKeyBackspace, L10n.calo.a11yKeyEnter,
        L10n.calo.a11yKeyClear, L10n.calo.a11ySettings, L10n.calo.a11yBack,
        L10n.shared.experimentsTitle, L10n.shared.experimentsOpenAs, L10n.shared.experimentsOpenAsFooter,
        L10n.shared.productCalo, L10n.shared.productCalculator,
    ]

    @Test("every L10n key has a value that is not the key itself")
    func keysResolve() {
        for resource in Self.resources {
            let value = String(localized: resource)
            #expect(value != resource.key, "missing: \(resource.key)")
            #expect(!value.isEmpty)
        }
    }

    @Test("format keys interpolate")
    func formats() {
        #expect(L10n.calo.a11yDashLogged(1240) == "Logged 1,240 calories")
        #expect(L10n.calo.a11yDashRemaining(-20) == "Remaining -20 calories")
    }

    @Test("the web app's copy is verbatim")
    func verbatim() {
        #expect(String(localized: L10n.calo.errorBusy) == "Still logging — please wait")
        #expect(String(localized: L10n.calo.aboutTagline) == "And 3-second calorie logging rocks.")
        #expect(String(localized: L10n.calo.settingsTodayLog) == "Today’s Log")
    }
}
