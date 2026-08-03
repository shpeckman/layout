# src/layout/rules.cr
module Layout
  struct Action
    getter layer      : Layer?
    getter stack      : String?
    getter weight     : Int32?
    getter fixed      : Int32?
    getter min        : Int32?
    getter max        : Int32?
    getter focus      : Bool?
    getter strut      : Strut?
    getter scratchpad : String?
    getter sticky     : Bool?
    getter workspace  : Int32?
    getter clear      : Field
    getter? stop      : Bool

    def initialize(@layer : Layer? = nil, @stack : String? = nil,
                   @weight : Int32? = nil, @fixed : Int32? = nil,
                   @min : Int32? = nil, @max : Int32? = nil,
                   @focus : Bool? = nil, @strut : Strut? = nil,
                   @scratchpad : String? = nil, @sticky : Bool? = nil,
                   @workspace : Int32? = nil, @clear : Field = Field::None,
                   @stop : Bool = false)
    end
  end

  struct Rule
    getter matcher  : Matcher
    getter action   : Action
    getter priority : Int32

    def initialize(@matcher : Matcher, @action : Action, @priority : Int32 = 0)
    end
  end

  struct Resolution
    getter target    : String?
    getter? focus    : Bool
    getter workspace : Int32?
    getter matched   : Array(Int32)

    def initialize(@target : String? = nil, @focus : Bool = false,
                   @workspace : Int32? = nil, @matched : Array(Int32) = [] of Int32)
    end

    def matched? : Bool
      !matched.empty?
    end

    def contested? : Bool
      matched.size > 1
    end
  end

  struct Change
    getter id             : Int32
    getter layer          : Layer
    getter previous       : Rect
    getter rect           : Rect
    getter previous_pixel : PixelRect
    getter pixel          : PixelRect
    getter? was_visible   : Bool
    getter? visible       : Bool

    def initialize(@id : Int32, @layer : Layer, @previous : Rect, @rect : Rect,
                   @previous_pixel : PixelRect, @pixel : PixelRect,
                   @was_visible : Bool, @visible : Bool)
    end

    def moved? : Bool
      previous != rect
    end

    def shifted? : Bool
      previous_pixel != pixel
    end

    def visibility_changed? : Bool
      was_visible? != visible?
    end

    def appeared? : Bool
      !was_visible? && visible?
    end

    def vanished? : Bool
      was_visible? && !visible?
    end
  end

  class Scratchpad
    getter name        : String
    property window_id : Int32?
    property? shown    : Bool
    property width     : Int32
    property height    : Int32

    def initialize(@name : String, @window_id : Int32? = nil,
                   @shown : Bool = false, @width : Int32 = 0, @height : Int32 = 0)
    end

    def bound? : Bool
      !window_id.nil?
    end
  end
end
