import SwiftUI

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
  /// Background color for non-current search matches.
  @Entry var searchMatchBackground = DynamicColor(
    light: Color.yellow.opacity(0.5),
    dark: Color.yellow.opacity(0.4)
  )

  /// Background color for the currently selected search match.
  @Entry var searchMatchCurrentBackground = DynamicColor(
    light: Color.orange.opacity(0.6),
    dark: Color.orange.opacity(0.5)
  )
}

// MARK: - View Modifier

extension View {
  /// Sets the search highlight colors for Textual rendering.
  ///
  /// Use this modifier to customize the background colors used for search match highlights.
  ///
  /// ```swift
  /// DocumentView()
  ///     .searchHighlightColors(
  ///         match: .yellow.opacity(0.5),
  ///         currentMatch: .orange.opacity(0.6)
  ///     )
  /// ```
  ///
  /// - Parameters:
  ///   - match: The background color for non-current search matches.
  ///   - currentMatch: The background color for the currently selected match.
  /// - Returns: A view with the search highlight colors configured.
  public func searchHighlightColors(
    match: Color,
    currentMatch: Color
  ) -> some View {
    self
      .environment(\.searchMatchBackground, DynamicColor(match))
      .environment(\.searchMatchCurrentBackground, DynamicColor(currentMatch))
  }

  /// Sets the search highlight colors using dynamic colors for light/dark mode adaptation.
  ///
  /// - Parameters:
  ///   - match: The dynamic background color for non-current search matches.
  ///   - currentMatch: The dynamic background color for the currently selected match.
  /// - Returns: A view with the search highlight colors configured.
  public func searchHighlightColors(
    match: DynamicColor,
    currentMatch: DynamicColor
  ) -> some View {
    self
      .environment(\.searchMatchBackground, match)
      .environment(\.searchMatchCurrentBackground, currentMatch)
  }
}
