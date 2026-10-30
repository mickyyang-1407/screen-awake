import AppKit
import Darwin
import IOKit.pwr_mgt
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.mickyyang.screen-awake", category: "PowerAssertion")
    private var assertionID: IOPMAssertionID?
    private var language = AppLanguage.system
    private var powerError: PowerError?
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private let panel = AwakePanelView()
    private var guideWindow: NSWindow?
    private let guide = SetupGuideView()
    private let guideItem = NSMenuItem(title: "", action: #selector(showGuide), keyEquivalent: "?")
    private let statusGuideItem = NSMenuItem(title: "", action: #selector(showGuide), keyEquivalent: "")
    private let helpMenuItem = NSMenuItem()
    private let menuState = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let menuToggle = NSMenuItem(title: "", action: #selector(toggleFromMenu), keyEquivalent: "")
    private let showItem = NSMenuItem(title: "", action: #selector(showWindow), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "", action: #selector(quit), keyEquivalent: "q")
    private let appQuitItem = NSMenuItem(title: "", action: #selector(quit), keyEquivalent: "q")
    private let controlsItem = NSMenuItem(title: "", action: #selector(showMenuBarControls), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        language = AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "system") ?? .system
        buildMenus()
        buildWindow()
        // Continuous display-awake is opt-in for each GUI launch, including upgrades.
        setEnabled(false)
        showWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let id = assertionID {
            let result = IOPMAssertionRelease(id)
            if result != kIOReturnSuccess { logger.error("Assertion release at quit failed: \(result)") }
            // macOS also clears any remaining assertion when its owning process exits.
            assertionID = nil
        }
    }

    private func setEnabled(_ enabled: Bool) {
        if enabled, assertionID == nil {
            var newID: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "ScreenAwake - Display stays on" as CFString, &newID
            )
            guard result == kIOReturnSuccess else { reportFailure(enabling: true, code: result); return }
            assertionID = newID
        } else if !enabled, let id = assertionID {
            let result = IOPMAssertionRelease(id)
            guard result == kIOReturnSuccess else { reportFailure(enabling: false, code: result); return }
            assertionID = nil
        }
        powerError = nil
        updateUI()
    }

    private func reportFailure(enabling: Bool, code: IOReturn) {
        powerError = PowerError(enabling: enabling, code: code)
        logger.error("Power assertion operation failed, enabling: \(enabling), code: \(code)")
        updateUI()
    }

    private func updateUI() {
        let enabled = assertionID != nil
        let text = AppText(language: language.resolved)
        panel.update(enabled: enabled, language: language, error: powerError)
        window.title = text.productName
        menuState.title = text.currentState(enabled)
        menuToggle.title = text.switchTitle
        menuToggle.state = enabled ? .on : .off
        showItem.title = text.showWindow
        quitItem.title = text.quit
        appQuitItem.title = text.quit
        controlsItem.title = text.menuBarControls
        guideItem.title = text.guideButton
        statusGuideItem.title = text.guideButton
        helpMenuItem.title = text.helpMenu
        guide.update(language: language)
        guideWindow?.title = text.guideButton
        let status = "\(text.productName): \(text.state(enabled))"
        statusItem.button?.toolTip = status
        statusItem.button?.setAccessibilityLabel(status)
        statusItem.button?.image = MenuBarIcon.image(enabled: enabled)
    }

    @objc private func toggleFromMenu() { setEnabled(assertionID == nil) }
    @objc private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func showMenuBarControls() {
        guard let button = statusItem.button, let menu = statusItem.menu else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button)
    }
    @objc private func showGuide() {
        if guideWindow == nil {
            let help = NSWindow(contentRect: NSRect(origin: .zero, size: SetupGuideView.panelSize),
                                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            help.isReleasedWhenClosed = false
            help.contentView = guide
            help.center()
            guideWindow = help
            guide.onDone = { [weak self] in self?.guideWindow?.close() }
        }
        guideWindow?.title = AppText(language: language.resolved).guideButton
        guideWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildMenus() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        controlsItem.target = self
        appMenu.addItem(controlsItem)
        appMenu.addItem(.separator())
        appQuitItem.target = self
        appMenu.addItem(appQuitItem)
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        let helpMenu = NSMenu()
        guideItem.target = self
        helpMenu.addItem(guideItem)
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        NSApp.helpMenu = helpMenu
        NSApp.mainMenu = mainMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "ScreenAwake.MenuBar"
        statusItem.isVisible = true
        statusItem.button?.setAccessibilityIdentifier("ScreenAwakeMenuBar")
        let menu = NSMenu()
        menu.addItem(menuState)
        menuToggle.target = self
        menu.addItem(menuToggle)
        menu.addItem(.separator())
        showItem.target = self
        menu.addItem(showItem)
        statusGuideItem.target = self
        menu.addItem(statusGuideItem)
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func buildWindow() {
        window = NSWindow(contentRect: NSRect(origin: .zero, size: AwakePanelView.panelSize),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = panel
        window.initialFirstResponder = panel.awakeSwitch
        panel.onToggle = { [weak self] enabled in self?.setEnabled(enabled) }
        panel.onGuide = { [weak self] in self?.showGuide() }
        panel.onLanguageChange = { [weak self] language in
            guard let self else { return }
            self.language = language
            self.defaults.set(language.rawValue, forKey: "appLanguage")
            self.updateUI()
        }
    }
}

@main
struct ScreenAwake {
    @MainActor static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if !arguments.isEmpty {
            exit(DisplayCommand.run(arguments: arguments))
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}
