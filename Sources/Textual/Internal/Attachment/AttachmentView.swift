import SwiftUI

// MARK: - Overview
//
// `AttachmentView` draws attachment bodies at the positions reported by SwiftUI's `Text.Layout`.
//
// The `Text` pipeline reserves space for attachments using placeholders; the overlay draws the
// real SwiftUI views on top of those placeholders. Drawing uses a `Canvas` so attachment views can
// be resolved once as symbols and efficiently drawn into each run's `typographicBounds`.
//
// Selection integration:
// On macOS, when text selection is enabled, object-style attachments are dimmed when they fall
// inside the selected range. Inline-style attachments (for example, emoji) are not dimmed.
//
// The `TextSelectionModel` is supplied by the parent (`AttachmentOverlay`) instead of being read
// from `@Environment` here. This view is created inside a `GeometryReader`, and an `@Environment`
// observable read in that position re-arms the layout subgraph on every measurement, producing an
// infinite SwiftUI layout invalidation loop (issue #26). The read happens even when a fragment has
// no attachments, so it must be hoisted out of the GeometryReader regardless of attachment count.

struct AttachmentView: View {
  private let attachments: Set<AnyAttachment>
  private let origin: CGPoint
  private let layout: Text.Layout
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    private let textSelectionModel: TextSelectionModel?

    init(
      attachments: Set<AnyAttachment>,
      origin: CGPoint,
      layout: Text.Layout,
      textSelectionModel: TextSelectionModel?
    ) {
      self.attachments = attachments
      self.origin = origin
      self.layout = layout
      self.textSelectionModel = textSelectionModel
    }
  #else
    init(
      attachments: Set<AnyAttachment>,
      origin: CGPoint,
      layout: Text.Layout
    ) {
      self.attachments = attachments
      self.origin = origin
      self.layout = layout
    }
  #endif

  var body: some View {
    Canvas { context, _ in
      context.translateBy(x: origin.x, y: origin.y)
      for (lineIndex, line) in zip(layout.indices, layout) {
        for (runIndex, run) in zip(line.indices, line) {
          guard
            let attachment = run.attachment,
            let symbol = context.resolveSymbol(id: attachment)
          else {
            continue
          }

          context.opacity = opacity(
            for: attachment,
            lineIndex: lineIndex,
            runIndex: runIndex
          )

          context.draw(symbol, in: run.typographicBounds.rect)
        }
      }
    } symbols: {
      ForEach(Array(attachments), id: \.self) { attachment in
        attachment.body
          .tag(attachment)
      }
    }
  }

  private func opacity(
    for attachment: AnyAttachment,
    lineIndex: Int,
    runIndex: Int
  ) -> CGFloat {
    #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
      guard
        attachment.selectionStyle == .object,
        let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange,
        let layoutIndex = textSelectionModel.layoutIndex(of: layout)
      else {
        return 1
      }

      let position = TextPosition(
        indexPath: .init(run: runIndex, line: lineIndex, layout: layoutIndex),
        affinity: .downstream
      )

      return selectedRange.contains(position) ? 0.5 : 1
    #else
      1
    #endif
  }
}
