import Foundation
import UniformTypeIdentifiers

/// The pasteboard side of Things drag and drop: one way to write a `ThingsDragPayload`
/// into a drag and one way to read it back. To-do rows and sidebar rows both drag through
/// `provider(for:)`; the list and the sidebar both accept `contentTypes`. The payload is
/// plain text, so no custom type has to be declared in Info.plist.
enum ThingsDragItem {
    /// What drop targets accept. The payload is registered as UTF-8 plain text, which
    /// conforms to plain text.
    static let contentTypes: [UTType] = [UTType.plainText]

    static func provider(for payload: ThingsDragPayload) -> NSItemProvider {
        NSItemProvider(object: payload.encoded as NSString)
    }

    /// Reads the payload of a drop. Nil when no provider carries one of ours (text dragged
    /// in from another app, say).
    static func load(from providers: [NSItemProvider]) async -> ThingsDragPayload? {
        for provider in providers where provider.canLoadObject(ofClass: String.self) {
            let text: String? = await withCheckedContinuation { continuation in
                _ = provider.loadObject(ofClass: String.self) { value, _ in
                    continuation.resume(returning: value)
                }
            }
            if let text = text, let payload = ThingsDragPayload(encoded: text) {
                return payload
            }
        }
        return nil
    }
}
