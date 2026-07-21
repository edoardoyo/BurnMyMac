import AppKit
import Combine

final class StatusBarController: NSObject {
    private let sleepPreventer: SleepPreventer
    private weak var guideWindowController: GuideWindowController?
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    init(sleepPreventer: SleepPreventer, guideWindowController: GuideWindowController) {
        self.sleepPreventer = sleepPreventer
        self.guideWindowController = guideWindowController
        super.init()
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        guard let button = item.button else { return }

        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "BurnMyMac — 点击保持 Mac 唤醒"

        sleepPreventer.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAppearance()
            }
            .store(in: &cancellables)

        updateAppearance()
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu(from: sender)
            return
        }

        sleepPreventer.toggle()
    }

    private func showMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()

        let toggleTitle = sleepPreventer.isActive ? "关闭保持唤醒" : "开启保持唤醒"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleFromMenu), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let guideItem = NSMenuItem(title: "使用指南…", action: #selector(showGuide), keyEquivalent: "g")
        guideItem.target = self
        menu.addItem(guideItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 BurnMyMac", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleFromMenu() {
        sleepPreventer.toggle()
    }

    @objc private func showGuide() {
        guideWindowController?.showGuide()
    }

    @objc private func quit() {
        sleepPreventer.setActive(false)
        NSApp.terminate(nil)
    }

    private func updateAppearance() {
        guard let button = statusItem?.button else { return }

        let symbolName = sleepPreventer.isActive ? "flame.fill" : "flame"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "BurnMyMac") {
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.isTemplate = true
            button.image = configured
        }

        if sleepPreventer.isActive {
            button.contentTintColor = .systemOrange
            button.toolTip = "保持唤醒中 — 点击关闭"
        } else {
            button.contentTintColor = nil
            button.toolTip = "BurnMyMac — 点击保持 Mac 唤醒"
        }
    }
}
