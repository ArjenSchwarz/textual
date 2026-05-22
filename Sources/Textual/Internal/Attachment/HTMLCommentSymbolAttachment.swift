import SwiftUI

/// An inline attachment that displays an SF Symbol as the prefix glyph for a
/// rendered HTML comment.
///
/// The attachment is purely decorative — accessibility consumers should read the
/// surrounding ``HTMLCommentRangeAttribute`` instead of announcing the symbol.
struct HTMLCommentSymbolAttachment: Attachment {
  let symbolName: String

  var description: String {
    // Plain-text description used by accessibility fallbacks and exports. The
    // host app (Prism) is expected to override this with a localised prefix
    // when exporting to plain text.
    "info"
  }

  var selectionStyle: AttachmentSelectionStyle {
    .text
  }

  @MainActor
  var body: some View {
    SwiftUI.Image(systemName: symbolName)
      .accessibilityHidden(true)
  }

  func baselineOffset(in _: TextEnvironmentValues) -> CGFloat {
    0
  }

  func sizeThatFits(_: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    // Use the resolved Dynamic Type scaled body size so the glyph tracks the
    // surrounding text. The exact metric is intentionally approximate — final
    // baseline alignment is handled by the text-layout pipeline.
    let scaledSize = approximateBodyPointSize(for: environment.dynamicTypeSize)
    return CGSize(width: scaledSize, height: scaledSize)
  }
}

private func approximateBodyPointSize(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
  switch dynamicTypeSize {
  case .xSmall: return 14
  case .small: return 15
  case .medium: return 16
  case .large: return 17
  case .xLarge: return 19
  case .xxLarge: return 21
  case .xxxLarge: return 23
  case .accessibility1: return 28
  case .accessibility2: return 33
  case .accessibility3: return 40
  case .accessibility4: return 47
  case .accessibility5: return 53
  @unknown default: return 17
  }
}
