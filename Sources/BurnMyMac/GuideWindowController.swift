import AppKit
import Combine

final class GuideWindowController: NSWindowController, NSWindowDelegate {
    private let sleepPreventer: SleepPreventer
    private var cancellables = Set<AnyCancellable>()
    private var statusBadge: NSView?
    private var statusDot: NSView?
    private var statusLabel: NSTextField?

    init(sleepPreventer: SleepPreventer) {
        self.sleepPreventer = sleepPreventer

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "BurnMyMac"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.center()

        super.init(window: window)
        window.delegate = self
        window.contentView = buildContentView()

        sleepPreventer.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusBadge()
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showGuide() {
        NSApp.setActivationPolicy(.regular)
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        updateStatusBadge()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func buildContentView() -> NSView {
        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true

        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20

        stack.addArrangedSubview(makeHeader())
        stack.addArrangedSubview(makeQuickStartCard())
        stack.addArrangedSubview(makeSection(
            title: "锁屏 vs 睡眠",
            subtitle: "很多困惑来自把「锁屏」和「睡眠」混在一起"
        ))
        stack.addArrangedSubview(makeComparisonTable())
        stack.addArrangedSubview(makeSection(
            title: "睡前推荐流程",
            subtitle: "整晚跑 Codex、脚本或下载任务时"
        ))
        stack.addArrangedSubview(makeChecklistCard())
        stack.addArrangedSubview(makeSection(
            title: "需要避免",
            subtitle: "以下操作会中断后台任务"
        ))
        stack.addArrangedSubview(makeAvoidCard())
        stack.addArrangedSubview(makeFooterNote())
        stack.addArrangedSubview(makeSilentStartButton())

        document.addSubview(stack)
        scrollView.documentView = document
        root.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -28),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -28),
            document.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stack.widthAnchor.constraint(equalTo: document.widthAnchor, constant: -56),
        ])

        return root
    }

    private func makeHeader() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown

        let title = label("BurnMyMac", size: 26, weight: .bold)
        let subtitle = label("保持 Mac 唤醒，让后台任务安心跑整夜", size: 13, weight: .regular)
        subtitle.textColor = .secondaryLabelColor

        let badge = makeStatusBadge()
        statusBadge = badge

        let textStack = NSStackView(views: [title, subtitle])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(textStack)
        container.addSubview(badge)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -12),

            badge.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            badge.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            container.bottomAnchor.constraint(equalTo: iconView.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 464),
        ])

        return container
    }

    private func makeStatusBadge() -> NSView {
        let badge = NSView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 10

        let dot = NSView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 4

        let text = label("未开启", size: 12, weight: .semibold)
        text.translatesAutoresizingMaskIntoConstraints = false
        statusLabel = text

        badge.addSubview(dot)
        badge.addSubview(text)

        statusDot = dot

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            dot.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),

            text.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            text.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            text.topAnchor.constraint(equalTo: badge.topAnchor, constant: 6),
            text.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -6),
        ])

        updateStatusBadge(in: badge, dot: dot, text: text)
        return badge
    }

    private func updateStatusBadge() {
        guard let badge = statusBadge,
              let dot = statusDot,
              let text = statusLabel else { return }
        updateStatusBadge(in: badge, dot: dot, text: text)
    }

    private func updateStatusBadge(in badge: NSView, dot: NSView, text: NSTextField) {
        let active = sleepPreventer.isActive
        badge.layer?.backgroundColor = active
            ? NSColor.systemOrange.withAlphaComponent(0.15).cgColor
            : NSColor.quaternaryLabelColor.withAlphaComponent(0.4).cgColor
        dot.layer?.backgroundColor = active
            ? NSColor.systemOrange.cgColor
            : NSColor.tertiaryLabelColor.cgColor
        text.stringValue = active ? "保持唤醒中" : "未开启"
        text.textColor = active ? .systemOrange : .secondaryLabelColor
    }

    private func makeQuickStartCard() -> NSView {
        card(
            rows: [
                ("左键单击菜单栏 🔥", "切换保持唤醒。图标变橙 = 已开启"),
                ("右键单击菜单栏 🔥", "打开菜单：切换、使用指南、退出"),
                ("开启后", "系统不会因空闲自动休眠；屏保和关屏不受影响"),
            ],
            accent: .systemBlue
        )
    }

    private func makeComparisonTable() -> NSView {
        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor

        let headers = ["操作", "系统", "后台程序", "网络"]
        let rows: [[String]] = [
            ["锁屏", "继续运行", "继续跑 ✓", "保持连接 ✓"],
            ["屏幕变黑", "继续运行", "继续跑 ✓", "保持连接 ✓"],
            ["睡眠", "挂起", "暂停 ✗", "可能断开 ✗"],
            ["关机", "停止", "停止 ✗", "断开 ✗"],
        ]

        let grid = NSGridView(views: [
            headers.map { headerCell($0) },
            rows[0].map { bodyCell($0, highlight: true) },
            rows[1].map { bodyCell($0, highlight: true) },
            rows[2].map { bodyCell($0, highlight: false) },
            rows[3].map { bodyCell($0, highlight: false) },
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 10
        grid.columnSpacing = 12
        grid.xPlacement = .fill
        grid.yPlacement = .center

        grid.column(at: 0).width = 72

        card.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            grid.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            grid.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            grid.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            card.widthAnchor.constraint(equalToConstant: 464),
        ])

        return card
    }

    private func makeChecklistCard() -> NSView {
        card(
            rows: [
                ("1", "打开 BurnMyMac，点一下菜单栏 🔥 让它变亮"),
                ("2", "放心锁屏，不必保持屏幕常亮"),
                ("3", "屏幕自动变黑没问题，后台任务会继续运行"),
            ],
            accent: .systemGreen,
            numbered: true
        )
    }

    private func makeAvoidCard() -> NSView {
        card(
            rows: [
                ("睡眠", "Apple 菜单 → 睡眠，会挂起系统和网络"),
                ("关机 / 重启", "所有任务都会停止"),
                ("笔记本合盖", "多数情况下会直接睡眠（硬件行为）"),
            ],
            accent: .systemRed
        )
    }

    private func makeFooterNote() -> NSView {
        let note = label(
            "BurnMyMac 不写配置文件、不留缓存。删除 App 即完全卸载。",
            size: 11,
            weight: .regular
        )
        note.textColor = .tertiaryLabelColor
        note.maximumNumberOfLines = 0
        note.lineBreakMode = .byWordWrapping
        return note
    }

    private func makeSilentStartButton() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let button = NSButton(title: "静默启动", target: self, action: #selector(silentStart))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentTintColor = .systemOrange

        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            container.widthAnchor.constraint(equalToConstant: 464),
            container.heightAnchor.constraint(equalToConstant: 36),
        ])

        return container
    }

    @objc private func silentStart() {
        window?.close()
    }

    private func makeSection(title: String, subtitle: String) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2

        stack.addArrangedSubview(label(title, size: 15, weight: .semibold))
        let sub = label(subtitle, size: 12, weight: .regular)
        sub.textColor = .secondaryLabelColor
        stack.addArrangedSubview(sub)
        return stack
    }

    private func card(
        rows: [(String, String)],
        accent: NSColor,
        numbered: Bool = false
    ) -> NSView {
        let card = NSView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor

        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(rowView(
                title: row.0,
                detail: row.1,
                accent: accent,
                numbered: numbered,
                number: index + 1
            ))
            if index < rows.count - 1 {
                stack.addArrangedSubview(separator())
            }
        }

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            card.widthAnchor.constraint(equalToConstant: 464),
        ])

        return card
    }

    private func rowView(
        title: String,
        detail: String,
        accent: NSColor,
        numbered: Bool,
        number: Int
    ) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let marker = NSView()
        marker.translatesAutoresizingMaskIntoConstraints = false
        marker.wantsLayer = true
        marker.layer?.cornerRadius = numbered ? 10 : 3
        marker.layer?.backgroundColor = accent.withAlphaComponent(numbered ? 0.15 : 0.9).cgColor

        if numbered {
            let num = label("\(number)", size: 12, weight: .bold)
            num.textColor = accent
            num.alignment = .center
            num.translatesAutoresizingMaskIntoConstraints = false
            marker.addSubview(num)
            NSLayoutConstraint.activate([
                num.centerXAnchor.constraint(equalTo: marker.centerXAnchor),
                num.centerYAnchor.constraint(equalTo: marker.centerYAnchor),
                marker.widthAnchor.constraint(equalToConstant: 20),
                marker.heightAnchor.constraint(equalToConstant: 20),
            ])
        } else {
            NSLayoutConstraint.activate([
                marker.widthAnchor.constraint(equalToConstant: 6),
                marker.heightAnchor.constraint(equalToConstant: 6),
            ])
        }

        let titleLabel = label(title, size: 13, weight: .semibold)
        let detailLabel = label(detail, size: 12, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(marker)
        row.addSubview(textStack)

        NSLayoutConstraint.activate([
            marker.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            marker.topAnchor.constraint(equalTo: row.topAnchor, constant: 3),

            textStack.leadingAnchor.constraint(equalTo: marker.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: row.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])

        return row
    }

    private func separator() -> NSView {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        line.widthAnchor.constraint(equalToConstant: 432).isActive = true
        return line
    }

    private func headerCell(_ text: String) -> NSTextField {
        let field = label(text, size: 11, weight: .semibold)
        field.textColor = .secondaryLabelColor
        return field
    }

    private func bodyCell(_ text: String, highlight: Bool) -> NSTextField {
        let field = label(text, size: 12, weight: highlight ? .medium : .regular)
        field.textColor = highlight ? .labelColor : .secondaryLabelColor
        field.maximumNumberOfLines = 2
        return field
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
