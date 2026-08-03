# src/layout/screen.cr
class Layout::Screen
  property cols     : Int32
  property rows     : Int32
  property cell     : CellSize
  getter background : StackedLayer
  getter sticky     : StackedLayer

  def initialize(@cols : Int32 = 0, @rows : Int32 = 0, @cell : CellSize = CellSize.new)
    @background = StackedLayer.new(Layer::Background)
    @sticky     = StackedLayer.new(Layer::Floating)
  end

  def bounds : Rect
    Rect.new(0, 0, cols, rows)
  end
end
