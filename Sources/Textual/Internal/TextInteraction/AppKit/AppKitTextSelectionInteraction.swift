#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionInteraction` presents the platform-specific text selection overlay for macOS.
  //
  // The modifier receives a `TextSelectionModel` and places it in the environment so selection highlights
  // and attachment dimming can access it. An overlay hosts `AppKitTextInteractionOverlay`, which wraps an
  // `NSView` that handles selection gestures and context menus. The modifier also manages cursor updates,
  // switching between I-beam and pointing hand based on hover position over text or links.

  typealias PlatformTextSelectionInteraction = AppKitTextSelectionInteraction

  struct AppKitTextSelectionInteraction: ViewModifier {
    @State private var cursorPushed = false

    private let model: TextSelectionModel

    init(model: TextSelectionModel) {
      self.model = model
    }

    func body(content: Content) -> some View {
      content
        // We need the selection model at text fragment level for
        // selected attachment dimming
        .environment(model)
        // One highlight layer per scope instead of one per fragment; see
        // the overview in AppKitTextSelectionView.
        .background(AppKitTextSelectionView(model: model))
        .overlayPreferenceValue(OverflowFrameKey.self) { frames in
          AppKitTextInteractionOverlay(model: model, overflowFrames: frames)
            .onContinuousHover { phase in
              updateCursor(for: phase, model: model)
            }
        }
    }

    private func updateCursor(for phase: HoverPhase, model: TextSelectionModel) {
      switch phase {
      case .active(let location):
        // The interaction overlay can span a whole document scope, so only
        // show text cursors when the pointer is actually over text.
        let cursor: NSCursor?
        if model.url(for: location) != nil {
          cursor = .pointingHand
        } else if model.containsText(at: location) {
          cursor = .iBeam
        } else {
          cursor = nil
        }

        if let cursor {
          if !cursorPushed {
            cursor.push()
            cursorPushed = true
          } else {
            cursor.set()
          }
        } else if cursorPushed {
          NSCursor.pop()
          cursorPushed = false
        }
      case .ended:
        if cursorPushed {
          NSCursor.pop()
          cursorPushed = false
        }
      }
    }
  }
#endif
