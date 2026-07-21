import AppKit

@main
enum BurnMyMacMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sleepPreventer = SleepPreventer()
    private var guideWindowController: GuideWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let guide = GuideWindowController(sleepPreventer: sleepPreventer)
        guideWindowController = guide

        let controller = StatusBarController(
            sleepPreventer: sleepPreventer,
            guideWindowController: guide
        )
        controller.install()
        statusBarController = controller

        guide.showGuide()
    }

    func applicationWillTerminate(_ notification: Notification) {
        sleepPreventer.setActive(false)
    }
}
