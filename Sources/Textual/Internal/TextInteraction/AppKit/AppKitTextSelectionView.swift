#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionView` renders selection highlights for a single `Text.Layout`.
  //
  // Each text fragment provides its own resolved layout and origin. The shared `TextSelectionModel`
  // is supplied by the parent (`TextSelectionBackground`) rather than read from `@Environment` here:
  // this view is created inside a `GeometryReader`, and an `@Environment` observable read in that
  // position re-arms the layout subgraph on every measurement, producing an infinite layout
  // invalidation loop (see issue #26). The view computes selection rectangles for the current range
  // within this layout and paints them in a `Canvas` behind the text.

  struct AppKitTextSelectionView: View {
    @State private var selectionRects: [TextSelectionRect] = []

    private let layout: Text.Layout
    private let origin: CGPoint
    private let textSelectionModel: TextSelectionModel?

    init(layout: Text.Layout, origin: CGPoint, textSelectionModel: TextSelectionModel?) {
      self.layout = layout
      self.origin = origin
      self.textSelectionModel = textSelectionModel
    }

    var body: some View {
      Group {
        if selectionRects.isEmpty {
          Color.clear
        } else {
          Canvas { context, _ in
            context.translateBy(x: origin.x, y: origin.y)
            for selectionRect in selectionRects {
              context.fill(
                Path(selectionRect.rect.integral),
                with: .color(.init(nsColor: .selectedTextBackgroundColor))
              )
            }
          }
        }
      }
      .onChange(of: textSelectionModel?.selectedRange, initial: true, updateSelectionRects)
      .onChange(of: layout, initial: true, updateSelectionRects)
    }

    private func updateSelectionRects() {
      if let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange
      {
        selectionRects = textSelectionModel.selectionRects(for: selectedRange, layout: layout)
      } else {
        selectionRects = []
      }
    }
  }
#endif
