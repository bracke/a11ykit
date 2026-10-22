// Walks the accessibility tree a11ykit exposes for a process, the way
// VoiceOver would reach it: through the public AXUIElement API.
import ApplicationServices
import Foundation

let pid = pid_t(CommandLine.arguments[1])!
print("AXIsProcessTrusted:", AXIsProcessTrusted())
var count = 0
var names: [String] = []

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
    return error == .success ? value : nil
}

func walk(_ element: AXUIElement, _ depth: Int) {
    count += 1
    let role = attribute(element, kAXRoleAttribute) as? String ?? "?"
    let title = (attribute(element, kAXTitleAttribute) as? String)
        ?? (attribute(element, kAXDescriptionAttribute) as? String) ?? ""
    names.append(title)
    print(String(repeating: "  ", count: depth) + "\(role) \"\(title)\"")
    if depth > 6 { return }
    for child in attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
        walk(child, depth + 1)
    }
}

let app = AXUIElementCreateApplication(pid)
var windows: CFTypeRef?
let error = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
print("windows attribute:", error.rawValue)
walk(app, 0)
print("elements", count)
if names.contains("first.txt") { print("found first.txt"); exit(0) }
print("first.txt not reachable"); exit(1)
