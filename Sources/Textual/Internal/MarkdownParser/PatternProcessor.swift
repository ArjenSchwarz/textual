import Foundation

// MARK: - Overview
//
// `PatternProcessor` applies pattern-based substitutions to an `AttributedString` after parsing.
// It walks each run, skips preformatted content, tokenizes the run’s text, and replaces tokens
// using the first matching syntax extension.
//
// The processor keeps run attributes intact for unchanged text and allows replacement logic to
// inject new attributes (for example, emoji URLs) while preserving the rest of the run’s metadata.
//
// Syntax extensions are opt-in; when no extensions are provided, the input is returned unchanged.
//
// Most extensions leave preformatted runs (code spans, inline HTML, code blocks) alone. The
// HTML-comment extension is an exception — comments arrive inside an `inlineHTML` run, so its
// pattern declares `processesInsideInlineHTML = true` and the processor tokenizes inline-HTML
// runs using only those opted-in patterns. Code spans and code blocks are still skipped for
// every extension.

extension AttributedStringMarkdownParser {
  struct PatternProcessor {
    private let syntaxExtensions: [SyntaxExtension]
    private let tokenizer: PatternTokenizer
    private let inlineHTMLTokenizer: PatternTokenizer
    private let hasInlineHTMLPatterns: Bool

    init(syntaxExtensions: [SyntaxExtension]) {
      self.syntaxExtensions = syntaxExtensions
      self.tokenizer = PatternTokenizer(patterns: syntaxExtensions.flatMap(\.patterns))
      let inlineHTMLPatterns = syntaxExtensions
        .flatMap(\.patterns)
        .filter(\.processesInsideInlineHTML)
      self.inlineHTMLTokenizer = PatternTokenizer(patterns: inlineHTMLPatterns)
      self.hasInlineHTMLPatterns = !inlineHTMLPatterns.isEmpty
    }

    func expand(_ attributedString: AttributedString) throws -> AttributedString {
      guard !syntaxExtensions.isEmpty else {
        return attributedString
      }

      var output = AttributedString()

      for run in attributedString.runs {
        if run.isCodeOrCodeBlock {
          // Code spans and code blocks are always preserved verbatim.
          output.append(attributedString[run.range])
        } else if run.isInlineHTML {
          if hasInlineHTMLPatterns {
            try processRun(
              attributedString: attributedString,
              run: run,
              tokenizer: inlineHTMLTokenizer,
              output: &output
            )
          } else {
            output.append(attributedString[run.range])
          }
        } else {
          try processRun(
            attributedString: attributedString,
            run: run,
            tokenizer: tokenizer,
            output: &output
          )
        }
      }

      return output
    }

    private func processRun(
      attributedString: AttributedString,
      run: AttributedString.Runs.Run,
      tokenizer: PatternTokenizer,
      output: inout AttributedString
    ) throws {
      let text = String(attributedString[run.range].characters[...])
      let tokens = try tokenizer.tokenize(text)

      if tokens.count == 1, tokens.first?.type == .text {
        output.append(attributedString[run.range])
      } else {
        for token in tokens {
          if let syntaxExtension = syntaxExtensions.firstMatching(token.type),
            let replacement = syntaxExtension.replace(token, run.attributes)
          {
            output.append(replacement)
          } else {
            output.append(AttributedString(token.content, attributes: run.attributes))
          }
        }
      }
    }

    /// Returns `true` when every position covered by `range` sits inside an
    /// inline code span run (a run whose `inlinePresentationIntent` contains
    /// `.code`) of `attributedString`.
    ///
    /// Code blocks (`presentationIntent.codeBlock`) also return `true`. The
    /// helper is used by syntax extensions that need to leave the literal
    /// substring untouched when it falls inside code.
    static func isInsideCodeSpan(
      range: Range<AttributedString.Index>,
      in attributedString: AttributedString
    ) -> Bool {
      guard range.lowerBound < range.upperBound else { return false }

      // Walk runs and ensure every run that intersects `range` is a code run.
      // A range fully contained in code spans / code blocks returns `true`.
      var foundAny = false
      for run in attributedString.runs {
        let intersection = run.range.clamped(to: range)
        guard intersection.lowerBound < intersection.upperBound else { continue }
        foundAny = true
        if !run.isCodeOrCodeBlock {
          return false
        }
      }
      return foundAny
    }
  }
}

extension Array where Element == AttributedStringMarkdownParser.SyntaxExtension {
  func firstMatching(_ tokenType: PatternTokenizer.TokenType) -> Element? {
    guard tokenType != .text else {
      return nil
    }
    return first {
      $0.patterns.map(\.tokenType).contains(tokenType)
    }
  }
}

extension AttributedString.Runs.Run {
  fileprivate var isCodeOrCodeBlock: Bool {
    if self.inlinePresentationIntent?.contains(.code) ?? false {
      return true
    }
    if self.presentationIntent?.isCodeBlock ?? false {
      return true
    }
    return false
  }

  fileprivate var isInlineHTML: Bool {
    if let intent = self.inlinePresentationIntent,
      intent.contains(.inlineHTML) || intent.contains(.blockHTML)
    {
      return true
    }
    return false
  }
}

extension PresentationIntent {
  fileprivate var isCodeBlock: Bool {
    components.first?.kind.isCodeBlock ?? false
  }
}

extension PresentationIntent.Kind {
  fileprivate var isCodeBlock: Bool {
    switch self {
    case .codeBlock:
      return true
    default:
      return false
    }
  }
}
