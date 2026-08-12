# src/layout/window.cr
class Layout::Window
  getter id           : Int32
  property app_id     : String
  property title      : String
  property tag        : String?
  property layer      : Layer
  property rect       : Rect
  property sizing     : Sizing
  property parent     : Int32?
  property strut      : Strut?
  property scratchpad : String?
  property mode       : Mode
  property? sticky    : Bool
  property? hidden    : Bool
  property? visible   : Bool

  def initialize(@id : Int32, @app_id : String, @title : String,
                 @tag : String? = nil, @layer : Layer = Layer::Tiled,
                 @rect : Rect = Rect::EMPTY, @sizing : Sizing = Sizing.new,
                 @parent : Int32? = nil, @strut : Strut? = nil,
                 @scratchpad : String? = nil, @mode : Mode = Mode::Normal,
                 @sticky : Bool = false, @hidden : Bool = false,
                 @visible : Bool = false)
  end

  def same?(other : Window) : Bool
    id == other.id
  end

  def panel? : Bool
    !strut.nil?
  end

  def scratchpad? : Bool
    !scratchpad.nil?
  end

  def modal? : Bool
    !parent.nil?
  end
end

