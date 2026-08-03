# src/layout/workspace.cr
class Layout::Workspace
  getter id           : Int32
  property name       : String?
  getter tiled        : TiledLayer
  getter floating     : StackedLayer
  getter overlay      : StackedLayer
  property fullscreen : Int32?
  property focused    : Int32?
  property direction  : Direction

  def initialize(@id : Int32, @name : String? = nil,
                 @direction : Direction = Direction::Horizontal)
    @tiled      = TiledLayer.new(Layer::Tiled)
    @floating   = StackedLayer.new(Layer::Floating)
    @overlay    = StackedLayer.new(Layer::Overlay)
    @fullscreen = nil
    @focused    = nil
  end

  def same_ref?(other : Workspace) : Bool
    id == other.id
  end

  def stacked(kind : Layer) : StackedLayer?
    case kind
    when Layer::Floating then @floating
    when Layer::Overlay  then @overlay
    else                      nil
    end
  end
end
