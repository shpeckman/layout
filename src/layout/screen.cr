# src/layout/screen.cr
class Layout::Screen
  property cols     : Int32
  property rows     : Int32
  getter origin     : Int32
  getter background : StackedLayer
  getter sticky     : StackedLayer

  def initialize(@cols : Int32 = 0, @rows : Int32 = 0, @origin : Int32 = 1)
    @background = StackedLayer.new(Layer::Background)
    @sticky     = StackedLayer.new(Layer::Floating)
  end

  def bounds : Rect
    Rect.new(origin, origin, cols, rows)
  end
end

