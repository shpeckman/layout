# src/layout/matchers.cr
module Layout
  struct AppIdCriterion
    getter value : String

    def initialize(@value : String)
    end

    def matches?(window : Window) : Bool
      window.app_id == value
    end
  end

  struct TitleCriterion
    getter pattern : Regex

    def initialize(@pattern : Regex)
    end

    def matches?(window : Window) : Bool
      window.title.matches?(pattern)
    end
  end

  struct TagCriterion
    getter value : String

    def initialize(@value : String)
    end

    def matches?(window : Window) : Bool
      window.tag == value
    end
  end

  struct LayerCriterion
    getter value : Layer

    def initialize(@value : Layer)
    end

    def matches?(window : Window) : Bool
      window.layer == value
    end
  end

  struct Always
    def matches?(window : Window) : Bool
      true
    end
  end

  struct Never
    def matches?(window : Window) : Bool
      false
    end
  end

  class All
    getter matchers : Array(Matcher)

    def initialize(@matchers : Array(Matcher) = [] of Matcher)
    end

    def matches?(window : Window) : Bool
      matchers.all? { |matcher| matcher.matches?(window) }
    end
  end

  class Any
    getter matchers : Array(Matcher)

    def initialize(@matchers : Array(Matcher) = [] of Matcher)
    end

    def matches?(window : Window) : Bool
      matchers.any? { |matcher| matcher.matches?(window) }
    end
  end

  class Not
    getter matcher : Matcher

    def initialize(@matcher : Matcher)
    end

    def matches?(window : Window) : Bool
      !matcher.matches?(window)
    end
  end

  alias Matcher = AppIdCriterion | TitleCriterion | TagCriterion |
                  LayerCriterion | Always | Never | All | Any | Not

  module Match
    def self.app_id(value : String) : Matcher
      AppIdCriterion.new(value)
    end

    def self.title(pattern : Regex) : Matcher
      TitleCriterion.new(pattern)
    end

    def self.tag(value : String) : Matcher
      TagCriterion.new(value)
    end

    def self.layer(value : Layer) : Matcher
      LayerCriterion.new(value)
    end

    def self.always : Matcher
      Always.new
    end

    def self.never : Matcher
      Never.new
    end

    def self.all(*matchers : Matcher) : Matcher
      collected = Array(Matcher).new(matchers.size)
      matchers.each { |matcher| collected << matcher }
      All.new(collected)
    end

    def self.all(matchers : Array(Matcher)) : Matcher
      All.new(matchers)
    end

    def self.any(*matchers : Matcher) : Matcher
      collected = Array(Matcher).new(matchers.size)
      matchers.each { |matcher| collected << matcher }
      Any.new(collected)
    end

    def self.any(matchers : Array(Matcher)) : Matcher
      Any.new(matchers)
    end

    def self.not(matcher : Matcher) : Matcher
      Not.new(matcher)
    end

    def self.build(app_id : String? = nil, title : Regex? = nil,
                   tag : String? = nil, layer : Layer? = nil) : Matcher
      matchers = [] of Matcher
      matchers << AppIdCriterion.new(app_id) if app_id
      matchers << TitleCriterion.new(title) if title
      matchers << TagCriterion.new(tag) if tag
      matchers << LayerCriterion.new(layer) if layer
      return Never.new if matchers.empty?
      All.new(matchers)
    end
  end
end
