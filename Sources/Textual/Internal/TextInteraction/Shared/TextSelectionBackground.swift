import SwiftUI

// MARK: - Overview
//
// `TextSelectionBackground` draws selection highlights behind a `Text` fragment.
//
// The platform selection interaction stores a `TextSelectionModel` in the environment at fragment
// scope. This modifier reads the fragment’s anchored `Text.Layout` and forwards it to the AppKit
// selection view so it can convert the current selected range into highlight rectangles.
//
// The `TextSelectionModel` is read from `@Environment` here, at the modifier level, and passed into
// `AppKitTextSelectionView` as a plain value. It must NOT be read with `@Environment` inside the
// `GeometryReader` below: doing so re-arms the layout subgraph on every measurement and triggers an
// infinite SwiftUI layout invalidation loop (issue #26). Reading it outside the GeometryReader keeps
// the observation dependency off the layout hot path.

struct TextSelectionBackground: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
      content
        .backgroundPreferenceValue(Text.LayoutKey.self) { value in
          if let anchoredLayout = value.first {
            GeometryReader { geometry in
              AppKitTextSelectionView(
                layout: anchoredLayout.layout,
                origin: geometry[anchoredLayout.origin],
                textSelectionModel: textSelectionModel
              )
            }
          }
        }
    #else
      content
    #endif
  }
}
