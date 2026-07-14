import Foundation
import AppKit
import ServiceManagement
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var forceQuitKey: Key = .q {
        didSet { save() }
    }
    @Published var forceQuitUsesCmd: Bool   = true { didSet { save() } }
    @Published var forceQuitUsesShift: Bool = true { didSet { save() } }
    @Published var forceQuitUsesOpt: Bool   = false { didSet { save() } }
    @Published var forceQuitUsesCtrl: Bool  = false { didSet { save() } }

    @Published var whitelistedRawKeys: [UInt16] = [144, 145, 146] {
        didSet { save() }
    }

    @Published var unlockOnSleep: Bool = true      { didSet { save() } }
    @Published var showOverlay: Bool   = true      { didSet { save() } }

    @Published var launchAtLogin: Bool = false {
        didSet {
            save()
            updateLaunchAtLogin()
        }
    }

    private let defaults = UserDefaults.standard

    private init() {
        load()
    }

    var builtCombo: KeyCombo {
        var mods: NSEvent.ModifierFlags = []
        if forceQuitUsesCmd   { mods.insert(.command) }
        if forceQuitUsesShift { mods.insert(.shift) }
        if forceQuitUsesOpt   { mods.insert(.option) }
        if forceQuitUsesCtrl  { mods.insert(.control) }
        return KeyCombo(key: forceQuitKey, modifiers: mods)
    }

    var whitelistedKeyCodes: Set<CGKeyCode> {
        Set(whitelistedRawKeys.map { CGKeyCode($0) })
    }

    private func save() {
        defaults.set(forceQuitKey.rawValue,       forKey: "forceQuitKey")
        defaults.set(forceQuitUsesCmd,            forKey: "forceQuitUsesCmd")
        defaults.set(forceQuitUsesShift,          forKey: "forceQuitUsesShift")
        defaults.set(forceQuitUsesOpt,            forKey: "forceQuitUsesOpt")
        defaults.set(forceQuitUsesCtrl,           forKey: "forceQuitUsesCtrl")
        defaults.set(whitelistedRawKeys,          forKey: "whitelistedRawKeys")
        defaults.set(unlockOnSleep,               forKey: "unlockOnSleep")
        defaults.set(showOverlay,                 forKey: "showOverlay")
        defaults.set(launchAtLogin,               forKey: "launchAtLogin")
    }

    private func load() {
        if let raw = defaults.string(forKey: "forceQuitKey"),
           let key = Key(rawValue: raw) {
            forceQuitKey = key
        }
        forceQuitUsesCmd   = defaults.object(forKey: "forceQuitUsesCmd")   as? Bool ?? true
        forceQuitUsesShift = defaults.object(forKey: "forceQuitUsesShift") as? Bool ?? true
        forceQuitUsesOpt   = defaults.object(forKey: "forceQuitUsesOpt")   as? Bool ?? false
        forceQuitUsesCtrl  = defaults.object(forKey: "forceQuitUsesCtrl")  as? Bool ?? false
        whitelistedRawKeys = defaults.object(forKey: "whitelistedRawKeys") as? [UInt16] ?? [144, 145, 146]
        unlockOnSleep      = defaults.object(forKey: "unlockOnSleep")      as? Bool ?? true
        showOverlay        = defaults.object(forKey: "showOverlay")        as? Bool ?? true
        launchAtLogin      = defaults.object(forKey: "launchAtLogin")      as? Bool ?? false
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            if launchAtLogin {
                if service.status != .enabled {
                    do {
                        try service.register()
                    } catch {
                        print("Failed to register login service: \(error.localizedDescription)")
                    }
                }
            } else {
                if service.status == .enabled {
                    do {
                        try service.unregister()
                    } catch {
                        print("Failed to unregister login service: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
