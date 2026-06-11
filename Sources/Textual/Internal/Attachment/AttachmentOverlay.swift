import SwiftUI

// MARK: - Overview
//
// `AttachmentOverlay` renders attachment views using resolved `Text.Layout` geometry.
//
// It’s applied at the text fragment level. The fragment exposes the resolved layout through the
// `Text.LayoutKey` preference; this modifier reads the anchored layout, converts its anchor to a
// concrete origin using `GeometryReader`, and installs an `AttachmentView` that draws attachments
// at their run bounds.
//
// The `TextSelectionModel` (used to dim attachments inside the selection) is read from
// `@Environment` here, at the modifier level, and passed into `AttachmentView`. It must NOT be read
// with `@Environment` inside the `GeometryReader` below: doing so re-arms the layout subgraph on
// every measurement and triggers an infinite SwiftUI layout invalidation loop (issue #26).

struct AttachmentOverlay: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif
  private let attachments: Set<AnyAttachment>

  init(attachments: Set<AnyAttachment>) {
    self.attachments = attachments
  }

  func body(content: Content) -> some View {
    if attachments.isEmpty {
      // No attachments to draw: skip the preference + GeometryReader +
      // selection-model-observing overlay entirely. For plain-text
      // fragments this removes the last per-fragment layer that both
      // re-evaluates on every measurement pass and subscribes to the
      // selection model — under a document-level selection scope there
      // are thousands of such fragments alive at once.
      content
    } else {
      content
        .overlayPreferenceValue(Text.LayoutKey.self) { value in
          if let anchoredLayout = value.first {
            GeometryReader { geometry in
              #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
                AttachmentView(
                  attachments: attachments,
                  origin: geometry[anchoredLayout.origin],
                  layout: anchoredLayout.layout,
                  textSelectionModel: textSelectionModel
                )
              #else
                AttachmentView(
                  attachments: attachments,
                  origin: geometry[anchoredLayout.origin],
                  layout: anchoredLayout.layout
                )
              #endif
            }
          }
        }
    }
  }
}
