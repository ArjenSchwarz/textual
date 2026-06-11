#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionView` renders the selection highlight for an entire
  // selection scope in a single `Canvas`.
  //
  // It replaces the previous per-fragment selection background
  // (`TextSelectionBackground`), whose preference + GeometryReader +
  // Environment plumbing inside every measured fragment subtree fed the
  // infinite layout loop on macOS when fragments lived in a lazy container
  // (issue #26 and the related T-1513 investigation). Here the highlight is
  // hosted once at the selection-interaction level, *outside* the measured
  // content: it reads the shared `TextSelectionModel` as a plain value and
  // recomputes its rectangles when the selected range or the layout
  // collection generation changes. Rectangles come from the model’s
  // aggregated layout collection and are already expressed in the scope’s
  // coordinate space, which matches this view’s bounds.

  struct AppKitTextSelectionView: View {
    @State private var selectionRects: [TextSelectionRect] = []

    private let model: TextSelectionModel

    init(model: TextSelectionModel) {
      self.model = model
    }

    var body: some View {
      Group {
        if selectionRects.isEmpty {
          Color.clear
        } else {
          Canvas { context, _ in
            for selectionRect in selectionRects {
              context.fill(
                Path(selectionRect.rect.integral),
                with: .color(.init(nsColor: .selectedTextBackgroundColor))
              )
            }
          }
        }
      }
      .allowsHitTesting(false)
      .onChange(of: model.selectedRange, initial: true, updateSelectionRects)
      .onChange(of: model.layoutGeneration, updateSelectionRects)
    }

    private func updateSelectionRects() {
      if let selectedRange = model.selectedRange {
        selectionRects = model.selectionRects(for: selectedRange)
      } else {
        selectionRects = []
      }
    }
  }
#endif
