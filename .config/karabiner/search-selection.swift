import AppKit
import ApplicationServices

enum Search: String {
    case duckduckgo, chatgpt

    func url(for text: String) -> URL {
        let prompt = self == .chatgpt ? "\"\(text)\" what does this mean" : text
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let query = prompt.addingPercentEncoding(withAllowedCharacters: allowed)!
        let host = self == .chatgpt ? "chatgpt.com" : "duckduckgo.com"
        return URL(string: "https://\(host)/?q=\(query)")!
    }
}

func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func highlightedText(in pid: pid_t) -> String? {
    let app = AXUIElementCreateApplication(pid)
    guard let focused = attribute(kAXFocusedUIElementAttribute, of: app),
        CFGetTypeID(focused) == AXUIElementGetTypeID()
    else { return nil }
    return attribute(kAXSelectedTextAttribute, of: focused as! AXUIElement) as? String
}

struct ClipboardSnapshot {
    let items: [NSPasteboardItem]

    init?(_ pasteboard: NSPasteboard) {
        var saved: [NSPasteboardItem] = []
        var remaining = 1024 * 1024
        for item in pasteboard.pasteboardItems ?? [] {
            let copy = NSPasteboardItem()
            for type in item.types {
                guard let data = item.data(forType: type), data.count <= remaining else { return nil }
                remaining -= data.count
                copy.setData(data, forType: type)
            }
            saved.append(copy)
        }
        items = saved
    }

    func restore(_ pasteboard: NSPasteboard, ifUnchanged count: Int) {
        guard pasteboard.changeCount == count else { return }
        pasteboard.clearContents()
        if !items.isEmpty { pasteboard.writeObjects(items) }
    }
}

func copiedText(from pid: pid_t, on pasteboard: NSPasteboard) -> String? {
    let originalCount = pasteboard.changeCount
    guard let snapshot = ClipboardSnapshot(pasteboard), pasteboard.changeCount == originalCount,
        NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
        let source = CGEventSource(stateID: .privateState),
        let down = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
        let up = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
    else { return nil }

    var copiedCount = originalCount
    defer {
        if copiedCount != originalCount { snapshot.restore(pasteboard, ifUnchanged: copiedCount) }
    }
    for event in [down, up] {
        event.flags = .maskCommand
        event.postToPid(pid)
    }

    let deadline = ContinuousClock.now + .milliseconds(250)
    while ContinuousClock.now < deadline {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return nil }
        let count = pasteboard.changeCount
        if count != originalCount {
            copiedCount = count
            if let text = pasteboard.string(forType: .string), !text.isEmpty { return text }
        }
        Thread.sleep(forTimeInterval: 0.005)
    }
    return nil
}

func fail(_ message: String) -> Never {
    fputs("Selection search: \(message)\n", stderr)
    exit(1)
}

func run() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard let name = arguments.first, let search = Search(rawValue: name), arguments.count <= 3,
        arguments.count == 1 || arguments[1] == "--print-url"
    else { fail("Usage: search-selection <duckduckgo|chatgpt> [--print-url [TEXT]]") }

    if arguments.count == 3 {
        print(search.url(for: arguments[2]).absoluteString)
        return
    }
    guard AXIsProcessTrusted() else {
        fail("Allow Accessibility access for the app running this helper, or for search-selection itself.")
    }
    guard let app = NSWorkspace.shared.frontmostApplication else { fail("No active application.") }
    let pid = app.processIdentifier
    AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.1)

    let lockURL = FileManager.default.temporaryDirectory.appendingPathComponent("search-selection.lock")
    let lock = open(lockURL.path, O_CREAT | O_CLOEXEC | O_NOFOLLOW | O_RDWR, 0o600)
    guard lock >= 0 else { fail("Could not open the selection lock.") }
    defer { close(lock) }
    guard flock(lock, LOCK_EX | LOCK_NB) == 0 else { return }

    var text = highlightedText(in: pid)
    if text?.isEmpty != false {
        let pasteboard = NSPasteboard.general
        text = copiedText(from: pid, on: pasteboard) ?? pasteboard.string(forType: .string)
    }
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
        fail("The active application changed. Try again.")
    }
    guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        fail("Select text or copy a search query first.")
    }
    let url = search.url(for: text)
    if arguments.count == 2 {
        print(url.absoluteString)
    } else if !NSWorkspace.shared.open(url) {
        fail("Could not open the browser.")
    }
}

run()
