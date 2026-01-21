import SwiftUI

/// A text property that applies search highlight background colors.
///
/// This property conforms to ``TextProperty`` and applies background color
/// attributes to mark text ranges as search matches. The color used depends
/// on whether the match is the currently selected one.
///
/// ## Usage
///
/// Use the static factory methods for convenience:
///
/// ```swift
/// let standardHighlight = SearchHighlightProperty.searchHighlight
/// let currentHighlight = SearchHighlightProperty.searchHighlightCurrent
/// ```
///
/// Or create directly with the `isCurrent` parameter:
///
/// ```swift
/// let highlight = SearchHighlightProperty(isCurrent: true)
/// ```
public struct SearchHighlightProperty: TextProperty {
  /// Whether this is the currently selected search match.
  public let isCurrent: Bool

  /// Creates a search highlight property.
  ///
  /// - Parameter isCurrent: True if this is the active/selected match, false for other matches.
  public init(isCurrent: Bool = false) {
    self.isCurrent = isCurrent
  }

  public func apply(
    in attributes: inout AttributeContainer,
    environment: TextEnvironmentValues
  ) {
    let color =
      isCurrent
      ? environment.searchMatchCurrentBackground
      : environment.searchMatchBackground
    if let resolvedColor = color.bestMatch(for: environment.colorEnvironment) {
      attributes.backgroundColor = resolvedColor
    }
  }
}

// MARK: - Static Factory Methods

extension TextProperty where Self == SearchHighlightProperty {
  /// Creates a search highlight property with the standard match background color.
  ///
  /// Use this for non-current search matches.
  public static var searchHighlight: Self {
    SearchHighlightProperty(isCurrent: false)
  }

  /// Creates a search highlight property with the current match background color.
  ///
  /// Use this for the currently selected search match.
  public static var searchHighlightCurrent: Self {
    SearchHighlightProperty(isCurrent: true)
  }
}
