import SwiftUI

// MARK: - Overview
//
// A text selection *scope* hoists the selection machinery — the selection
// model, the platform interaction overlay, the highlight layer, and the
// `.textContainer` coordinate space — to a single host level that can wrap an
// arbitrary container of Textual views (for example, an application's own
// stack of `InlineText` blocks).
//
// Inside a scope, `InlineText` and `StructuredText` skip their per-view
// selection plumbing entirely; their fragments only publish inert
// `Text.LayoutKey` anchor preferences that flow up to the scope. This is what
// allows fragments to live inside lazy containers (`LazyVStack`): the loop
// documented in issue #26 (and the T-1513 investigation) required selection
// machinery *inside* the measured per-fragment subtrees, which no longer
// exists.
//
// `StructuredText` itself is implemented as a scope around its block content.
// Scopes do not nest: an inner scope dissolves into the outermost one.

struct TextSelectionScopeModifier: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(\.isInsideTextSelectionScope) private var isInsideScope
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if isInsideScope {
        // Dissolve into the outer scope: fragments below publish their
        // anchors upward; the outer scope owns model and interaction.
        content.modifier(ScopeMemberPreferenceFilter())
      } else {
        content
          .environment(\.isInsideTextSelectionScope, textSelection.allowsSelection)
          .modifier(TextSelectionInteraction())
          .modifier(TextSelectionCoordination())
          .coordinateSpace(.textContainer)
      }
    #else
      content
    #endif
  }
}

/// Applies `InlineText`'s standalone selection interaction unless an
/// enclosing selection scope already owns it.
struct StandaloneTextSelectionInteraction: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.isInsideTextSelectionScope) private var isInsideScope
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if isInsideScope {
        content.modifier(ScopeMemberPreferenceFilter())
      } else {
        content.modifier(TextSelectionInteraction())
      }
    #else
      content
    #endif
  }
}

/// Declares `InlineText`'s standalone `.textContainer` coordinate space
/// unless an enclosing selection scope already declares it. Inside a scope
/// the container-size reads and overflow exclusion frames must resolve
/// against the scope's space, not a per-view one.
struct StandaloneTextContainer: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.isInsideTextSelectionScope) private var isInsideScope
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if isInsideScope {
        content
      } else {
        content.coordinateSpace(.textContainer)
      }
    #else
      content.coordinateSpace(.textContainer)
    #endif
  }
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  /// Keeps a scope member's text out of the scope's selection collection when
  /// the member itself opts out via `.textual.textSelection(.disabled)` —
  /// e.g. text that doubles as a tap target. Clearing the anchor preference
  /// removes it from both selection and the interaction overlay's hit-test
  /// region; fragment-internal consumers (attachments, link taps) read the
  /// preference below this point and are unaffected.
  private struct ScopeMemberPreferenceFilter: ViewModifier {
    @Environment(\.textSelection) private var textSelection

    func body(content: Content) -> some View {
      if textSelection.allowsSelection {
        content
      } else {
        content.transformPreference(Text.LayoutKey.self) { $0 = [] }
      }
    }
  }

  extension EnvironmentValues {
    @Entry var isInsideTextSelectionScope: Bool = false
  }
#endif
