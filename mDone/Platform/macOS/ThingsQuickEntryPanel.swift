import SwiftUI

#if os(macOS)
import AppKit
import ApplicationServices

/// A floating panel that can take keyboard input without a visible main window.
final class ThingsQuickEntryNSPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Quick Entry (spec 04 section 5): a small floating panel to capture a to-do
/// into the Inbox from anywhere. The menu command (Ctrl Space, in the app) always
/// works. The system wide hotkey uses `NSEvent.addGlobalMonitorForEvents`,
/// which only sees keys when the user granted Accessibility access in System
/// Settings, so it is installed only when `AXIsProcessTrusted()` says yes and
/// never prompts by itself. A global monitor observes keys but cannot consume
/// them: macOS may also react to Ctrl Space (input source switching).
/// Autofill, tags, When and Deadline in the panel are TODOs (DEVIATIONS.md).
@MainActor
final class ThingsQuickEntryController {
    static let shared = ThingsQuickEntryController()

    private var appState: AppState?
    private var panel: ThingsQuickEntryNSPanel?
    private var globalMonitor: Any?
    private var activationObserver: NSObjectProtocol?

    /// Key code of the space bar.
    private let spaceKeyCode: UInt16 = 49

    private init() {}

    /// Called once by the Things window. Installs the hotkey when allowed, and
    /// tries again each time the app becomes active, so granting access takes
    /// effect without a restart.
    func configure(appState: AppState) {
        self.appState = appState
        installGlobalHotkeyIfTrusted()
        if activationObserver == nil {
            activationObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    ThingsQuickEntryController.shared.installGlobalHotkeyIfTrusted()
                }
            }
        }
    }

    func installGlobalHotkeyIfTrusted() {
        if globalMonitor != nil { return }
        guard AXIsProcessTrusted() else { return }
        let keyCode = spaceKeyCode
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == keyCode && flags == .control {
                Task { @MainActor in
                    ThingsQuickEntryController.shared.show()
                }
            }
        }
    }

    /// Asks macOS to show the Accessibility prompt. Only a user action calls this.
    func requestGlobalHotkeyAccess() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func show() {
        guard let appState = appState, appState.isAuthenticated else { return }
        close()
        let content = ThingsQuickEntryView(appState: appState, onClose: { [weak self] in self?.close() })
        let newPanel = ThingsQuickEntryNSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 180),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.hidesOnDeactivate = false
        newPanel.isReleasedWhenClosed = false
        newPanel.contentView = NSHostingView(rootView: content)
        newPanel.center()
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel = newPanel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}

/// The content of the panel: a title, notes and Save and Cancel (Esc discards,
/// Cmd Return saves, spec 04 section 5).
struct ThingsQuickEntryView: View {
    let appState: AppState
    let onClose: () -> Void

    @State private var title = ""
    @State private var notes = ""
    @FocusState private var titleFocused: Bool
    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                ThingsCheckbox(state: .open)
                TextField(String(localized: "New To-Do"), text: $title)
                    .textFieldStyle(.plain)
                    .font(ThingsTypography.todoTitle)
                    .focused($titleFocused)
                    .onSubmit { save() }
            }
            TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(ThingsTypography.notes)
                .lineLimit(2...6)
                .padding(.leading, ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing)
            HStack {
                Label(String(localized: "Inbox"), systemImage: ThingsIcons.inbox)
                    .font(ThingsTypography.deadline)
                    .foregroundStyle(palette[.textSecondary])
                Spacer()
                Button(String(localized: "Cancel")) { onClose() }
                    .keyboardShortcut(.cancelAction)
                Button(String(localized: "Save")) { save() }
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(ThingsMetrics.Card.innerPadding)
        .frame(width: 460)
        .background(palette[.bgExpandedTodo])
        .onAppear { titleFocused = true }
        .onExitCommand { onClose() }
    }

    private func save() {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = notes
        if text.isEmpty {
            onClose()
            return
        }
        let state = appState
        Task { @MainActor in
            let listModel = ThingsListViewModel(list: .inbox, appState: state)
            if let created = await listModel.quickAdd(title: text), !note.isEmpty {
                await state.updateTask(id: created.id, request: TaskUpdateRequest(description: note))
            }
        }
        onClose()
    }
}

#endif
