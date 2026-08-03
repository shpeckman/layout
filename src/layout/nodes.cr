# src/layout/nodes.cr
module Layout
  class Stack
    getter id         : Int32
    property name     : String?
    getter windows    : Array(Window)
    getter active     : Int32
    property rect     : Rect
    property sizing   : Sizing
    property tab_rows : Int32

    def initialize(@id : Int32, @name : String? = nil,
                   @windows : Array(Window) = [] of Window,
                   @active : Int32 = 0, @rect : Rect = Rect::EMPTY,
                   @sizing : Sizing = Sizing.new, @tab_rows : Int32 = 0)
    end

    def same?(other : Node) : Bool
      other.is_a?(Stack) && id == other.id
    end

    def size : Int32
      windows.size
    end

    def empty? : Bool
      windows.empty?
    end

    def active_window : Window?
      windows[active]?
    end

    def tab_rect : Rect
      reserved = tab_rows
      reserved = 0 if reserved < 0
      reserved = rect.rows if reserved > rect.rows
      Rect.new(rect.x, rect.y, rect.cols, reserved)
    end

    def content_rect : Rect
      reserved = tab_rect.rows
      Rect.new(rect.x, rect.y + reserved, rect.cols, rect.rows - reserved)
    end

    def index_of(window_id : Int32) : Int32?
      windows.index { |window| window.id == window_id }
    end

    def add(window : Window) : Window
      windows << window
      window
    end

    def remove(window_id : Int32) : Window?
      index = index_of(window_id)
      return nil unless index
      removed = windows.delete_at(index)
      @active -= 1 if index < @active
      limit   = windows.size - 1
      @active = limit if @active > limit
      @active = 0 if @active < 0
      removed
    end

    def focus(window_id : Int32) : Status
      index = index_of(window_id)
      return Status::Missing unless index
      focus_index(index)
    end

    def focus_index(index : Int32) : Status
      return Status::Missing if index < 0 || index >= windows.size
      return Status::Unchanged if index == @active
      @active = index
      Status::Changed
    end

    def focus_next : Status
      return Status::Unchanged if windows.size <= 1
      focus_index((@active + 1) % windows.size)
    end

    def focus_prev : Status
      return Status::Unchanged if windows.size <= 1
      focus_index((@active - 1) % windows.size)
    end

    def reorder(window_id : Int32, to : Int32) : Status
      index = index_of(window_id)
      return Status::Missing unless index
      destination = to.clamp(0, windows.size - 1)
      return Status::Unchanged if destination == index
      focused = windows[@active]?
      moved   = windows.delete_at(index)
      windows.insert(destination, moved)
      if focused
        found   = windows.index { |window| window.same?(focused) }
        @active = found if found
      end
      Status::Changed
    end
  end

  class Split
    getter id        : Int32
    getter direction : Direction
    getter children  : Array(Node)
    property rect    : Rect
    property sizing  : Sizing

    def initialize(@id : Int32, @direction : Direction,
                   @children : Array(Node) = [] of Node,
                   @rect : Rect = Rect::EMPTY, @sizing : Sizing = Sizing.new)
    end

    def same?(other : Node) : Bool
      other.is_a?(Split) && id == other.id
    end

    def size : Int32
      children.size
    end

    def empty? : Bool
      children.empty?
    end

    def set_direction(direction : Direction) : Status
      return Status::Unchanged if @direction == direction
      @direction = direction
      Status::Changed
    end

    def toggle_direction : Direction
      @direction = direction.horizontal? ? Direction::Vertical : Direction::Horizontal
    end

    def index_of(node : Node) : Int32?
      children.index { |child| child.same?(node) }
    end

    def reorder(node : Node, to : Int32) : Status
      index = index_of(node)
      return Status::Missing unless index
      destination = to.clamp(0, children.size - 1)
      return Status::Unchanged if destination == index
      moved = children.delete_at(index)
      children.insert(destination, moved)
      Status::Changed
    end

    def swap(first : Node, second : Node) : Status
      a = index_of(first)
      b = index_of(second)
      return Status::Missing unless a && b
      return Status::Unchanged if a == b
      children[a], children[b] = children[b], children[a]
      Status::Changed
    end

    def promotable? : Bool
      children.size == 1
    end

    def promote : Node?
      children.size == 1 ? children.first : nil
    end
  end

  alias Node = Split | Stack
end
