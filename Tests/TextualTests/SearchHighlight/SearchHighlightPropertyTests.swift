import SwiftUI
import Testing

@testable import Textual

@Suite("SearchHighlightProperty")
struct SearchHighlightPropertyTests {

  // MARK: - Initialization Tests

  @Test("creates property with isCurrent false by default")
  func defaultIsCurrentFalse() {
    let property = SearchHighlightProperty()
    #expect(property.isCurrent == false)
  }

  @Test("creates property with isCurrent true")
  func explicitIsCurrentTrue() {
    let property = SearchHighlightProperty(isCurrent: true)
    #expect(property.isCurrent == true)
  }

  @Test("creates property with isCurrent false explicitly")
  func explicitIsCurrentFalse() {
    let property = SearchHighlightProperty(isCurrent: false)
    #expect(property.isCurrent == false)
  }

  // MARK: - Apply Tests

  @Test("applies background color for non-current highlight")
  func applyNonCurrentHighlight() {
    var attributes = AttributeContainer()
    let property = SearchHighlightProperty(isCurrent: false)
    let environment = TextEnvironmentValues()

    property.apply(in: &attributes, environment: environment)

    #expect(attributes.backgroundColor != nil)
  }

  @Test("applies background color for current highlight")
  func applyCurrentHighlight() {
    var attributes = AttributeContainer()
    let property = SearchHighlightProperty(isCurrent: true)
    let environment = TextEnvironmentValues()

    property.apply(in: &attributes, environment: environment)

    #expect(attributes.backgroundColor != nil)
  }

  @Test("current and non-current have different background colors")
  func colorsAreDifferent() {
    var nonCurrentAttrs = AttributeContainer()
    var currentAttrs = AttributeContainer()
    let environment = TextEnvironmentValues()

    SearchHighlightProperty(isCurrent: false)
      .apply(in: &nonCurrentAttrs, environment: environment)
    SearchHighlightProperty(isCurrent: true)
      .apply(in: &currentAttrs, environment: environment)

    #expect(nonCurrentAttrs.backgroundColor != currentAttrs.backgroundColor)
  }

  // MARK: - Static Factory Method Tests

  @Test("searchHighlight factory creates non-current property")
  func searchHighlightFactory() {
    let property: SearchHighlightProperty = .searchHighlight
    #expect(property.isCurrent == false)
  }

  @Test("searchHighlightCurrent factory creates current property")
  func searchHighlightCurrentFactory() {
    let property: SearchHighlightProperty = .searchHighlightCurrent
    #expect(property.isCurrent == true)
  }

  // MARK: - Hashable/Equatable Tests

  @Test("properties with same isCurrent are equal")
  func equalityWithSameValue() {
    let property1 = SearchHighlightProperty(isCurrent: true)
    let property2 = SearchHighlightProperty(isCurrent: true)
    #expect(property1 == property2)
  }

  @Test("properties with different isCurrent are not equal")
  func inequalityWithDifferentValue() {
    let property1 = SearchHighlightProperty(isCurrent: true)
    let property2 = SearchHighlightProperty(isCurrent: false)
    #expect(property1 != property2)
  }

  @Test("property is Sendable")
  func sendableConformance() {
    let property = SearchHighlightProperty(isCurrent: true)
    // If this compiles, the property is Sendable
    Task { @Sendable in
      _ = property.isCurrent
    }
  }

  @Test("property is Hashable and can be used in Set")
  func hashableConformance() {
    let set: Set<SearchHighlightProperty> = [
      SearchHighlightProperty(isCurrent: true),
      SearchHighlightProperty(isCurrent: false),
      SearchHighlightProperty(isCurrent: true),  // duplicate
    ]
    #expect(set.count == 2)
  }
}
