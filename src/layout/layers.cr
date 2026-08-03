# src/layout/layers.cr
module Layout
  class TiledLayer
    getter layer  : Layer
    property root : Node?

    def initialize(@layer : Layer = Layer::Tiled, @root : Node? = nil)
    end
  end

  class StackedLayer
    getter layer   : Layer
    getter windows : Array(Window)

    def initialize(@layer : Layer, @windows : Array(Window) = [] of Window)
    end

    def index_of(window : Window) : Int32?
      windows.index { |candidate| candidate.same?(window) }
    end

    def add(window : Window) : Window
      windows << window
      window
    end

    def remove(window : Window) : Bool
      index = index_of(window)
      return false unless index
      windows.delete_at(index)
      true
    end

    def raise(window : Window) : Status
      shift(window, 1)
    end

    def lower(window : Window) : Status
      shift(window, -1)
    end

    def raise_to_top(window : Window) : Status
      move_to(window, windows.size - 1)
    end

    def lower_to_bottom(window : Window) : Status
      move_to(window, 0)
    end

    private def shift(window : Window, step : Int32) : Status
      index = index_of(window)
      return Status::Missing unless index
      move_to(window, index + step)
    end

    private def move_to(window : Window, destination : Int32) : Status
      index = index_of(window)
      return Status::Missing unless index
      bounded = destination.clamp(0, windows.size - 1)
      return Status::Unchanged if bounded == index
      moved = windows.delete_at(index)
      windows.insert(bounded, moved)
      Status::Changed
    end
  end

  alias RenderLayer = TiledLayer | StackedLayer
end
