# src/layout.cr
module Layout
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  enum Status
    Changed
    Unchanged
    Missing
    Rejected

    def success? : Bool
      changed? || unchanged?
    end
  end

  enum Direction
    Horizontal
    Vertical
  end

  enum Edge
    Left
    Right
    Up
    Down

    def direction : Direction
      left? || right? ? Direction::Horizontal : Direction::Vertical
    end

    def forward? : Bool
      right? || down?
    end
  end

  enum Side
    Top
    Bottom
    Left
    Right

    def direction : Direction
      left? || right? ? Direction::Horizontal : Direction::Vertical
    end
  end

  enum Layer
    Background = 0
    Tiled      = 1
    Floating   = 2
    Overlay    = 3
  end

  enum Mode
    Normal
    Maximized
    Fullscreen

    def override? : Bool
      maximized? || fullscreen?
    end
  end

  @[Flags]
  enum Field
    Layer
    Stack
    Weight
    Fixed
    Min
    Max
    Focus
    Strut
    Scratchpad
    Sticky
    Workspace
  end

  struct Rect
    getter x : Int32
    getter y : Int32
    getter cols : Int32
    getter rows : Int32

    def initialize(@x : Int32 = 0, @y : Int32 = 0, @cols : Int32 = 0, @rows : Int32 = 0)
    end

    def right : Int32
      x + cols
    end

    def bottom : Int32
      y + rows
    end

    def center_x : Int32
      x + cols // 2
    end

    def center_y : Int32
      y + rows // 2
    end

    def empty? : Bool
      cols <= 0 || rows <= 0
    end

    def contains?(px : Int32, py : Int32) : Bool
      px >= x && py >= y && px < right && py < bottom
    end

    def contains?(other : Rect) : Bool
      other.x >= x && other.y >= y && other.right <= right && other.bottom <= bottom
    end

    def intersects?(other : Rect) : Bool
      x < other.right && other.x < right && y < other.bottom && other.y < bottom
    end

    def translate(dx : Int32, dy : Int32) : Rect
      Rect.new(x + dx, y + dy, cols, rows)
    end

    def inset(amount : Int32) : Rect
      inset(amount, amount, amount, amount)
    end

    def inset(left : Int32, top : Int32, right : Int32, bottom : Int32) : Rect
      width = cols - left - right
      height = rows - top - bottom
      Rect.new(x + left, y + top, width > 0 ? width : 0, height > 0 ? height : 0)
    end

    def span(direction : Direction) : Int32
      direction.horizontal? ? cols : rows
    end

    def offset(direction : Direction) : Int32
      direction.horizontal? ? x : y
    end

    def slice(direction : Direction, offset : Int32, span : Int32) : Rect
      if direction.horizontal?
        Rect.new(offset, y, span, rows)
      else
        Rect.new(x, offset, cols, span)
      end
    end

    def centered(width : Int32, height : Int32) : Rect
      w = width > cols ? cols : width
      h = height > rows ? rows : height
      Rect.new(x + (cols - w) // 2, y + (rows - h) // 2, w, h)
    end

    def band(side : Side, size : Int32) : Rect
      thickness = size
      case side
      in Side::Top
        thickness = rows if thickness > rows
        Rect.new(x, y, cols, thickness)
      in Side::Bottom
        thickness = rows if thickness > rows
        Rect.new(x, bottom - thickness, cols, thickness)
      in Side::Left
        thickness = cols if thickness > cols
        Rect.new(x, y, thickness, rows)
      in Side::Right
        thickness = cols if thickness > cols
        Rect.new(right - thickness, y, thickness, rows)
      end
    end
  end

  struct CellSize
    getter width : Int32
    getter height : Int32

    def initialize(@width : Int32 = 1, @height : Int32 = 1)
    end
  end

  struct PixelRect
    getter x : Int32
    getter y : Int32
    getter width : Int32
    getter height : Int32

    def initialize(@x : Int32 = 0, @y : Int32 = 0, @width : Int32 = 0, @height : Int32 = 0)
    end
  end

  struct Sizing
    getter weight : Int32
    getter fixed : Int32?
    getter min : Int32?
    getter max : Int32?

    def initialize(@weight : Int32 = 1, @fixed : Int32? = nil,
                   @min : Int32? = nil, @max : Int32? = nil)
    end

    def fixed? : Bool
      !fixed.nil?
    end

    def with_weight(value : Int32) : Sizing
      Sizing.new(value, fixed, min, max)
    end

    def with_fixed(value : Int32?) : Sizing
      Sizing.new(weight, value, min, max)
    end

    def with_min(value : Int32?) : Sizing
      Sizing.new(weight, fixed, value, max)
    end

    def with_max(value : Int32?) : Sizing
      Sizing.new(weight, fixed, min, value)
    end

    def clamp_span(span : Int32) : Int32
      result = span
      if low = min
        result = low if result < low
      end
      if high = max
        result = high if result > high
      end
      result
    end
  end

  struct Strut
    getter side : Side
    getter size : Int32

    def initialize(@side : Side, @size : Int32 = 0)
    end

    def active? : Bool
      size > 0
    end
  end

  class Window
    getter id : Int32
    property app_id : String
    property title : String
    property tag : String?
    property layer : Layer
    property rect : Rect
    property sizing : Sizing
    property pixel : PixelRect
    property parent : Int32?
    property strut : Strut?
    property scratchpad : String?
    property mode : Mode
    property? sticky : Bool
    property? hidden : Bool
    property? visible : Bool

    def initialize(@id : Int32, @app_id : String, @title : String,
                   @tag : String? = nil, @layer : Layer = Layer::Tiled,
                   @rect : Rect = Rect.new, @sizing : Sizing = Sizing.new,
                   @pixel : PixelRect = PixelRect.new, @parent : Int32? = nil,
                   @strut : Strut? = nil, @scratchpad : String? = nil,
                   @mode : Mode = Mode::Normal, @sticky : Bool = false,
                   @hidden : Bool = false, @visible : Bool = false)
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

  class Stack
    getter id : Int32
    property name : String?
    getter windows : Array(Window)
    getter active : Int32
    property rect : Rect
    property sizing : Sizing
    property tab_rows : Int32

    def initialize(@id : Int32, @name : String? = nil,
                   @windows : Array(Window) = [] of Window,
                   @active : Int32 = 0, @rect : Rect = Rect.new,
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
      limit = windows.size - 1
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
      moved = windows.delete_at(index)
      windows.insert(destination, moved)
      if focused
        found = windows.index { |window| window.same?(focused) }
        @active = found if found
      end
      Status::Changed
    end
  end

  class Split
    getter id : Int32
    getter direction : Direction
    getter children : Array(Node)
    property rect : Rect
    property sizing : Sizing

    def initialize(@id : Int32, @direction : Direction,
                   @children : Array(Node) = [] of Node,
                   @rect : Rect = Rect.new, @sizing : Sizing = Sizing.new)
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

  class TiledLayer
    getter layer : Layer
    property root : Node?

    def initialize(@layer : Layer = Layer::Tiled, @root : Node? = nil)
    end
  end

  class StackedLayer
    getter layer : Layer
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

  class Workspace
    getter id : Int32
    property name : String?
    getter tiled : TiledLayer
    getter floating : StackedLayer
    getter overlay : StackedLayer
    property fullscreen : Int32?
    property focused : Int32?
    property direction : Direction

    def initialize(@id : Int32, @name : String? = nil,
                   @direction : Direction = Direction::Horizontal)
      @tiled = TiledLayer.new(Layer::Tiled)
      @floating = StackedLayer.new(Layer::Floating)
      @overlay = StackedLayer.new(Layer::Overlay)
      @fullscreen = nil
      @focused = nil
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

  class Screen
    property cols : Int32
    property rows : Int32
    property cell : CellSize
    getter background : StackedLayer
    getter sticky : StackedLayer

    def initialize(@cols : Int32 = 0, @rows : Int32 = 0, @cell : CellSize = CellSize.new)
      @background = StackedLayer.new(Layer::Background)
      @sticky = StackedLayer.new(Layer::Floating)
    end

    def bounds : Rect
      Rect.new(0, 0, cols, rows)
    end
  end

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

  struct Action
    getter layer : Layer?
    getter stack : String?
    getter weight : Int32?
    getter fixed : Int32?
    getter min : Int32?
    getter max : Int32?
    getter focus : Bool?
    getter strut : Strut?
    getter scratchpad : String?
    getter sticky : Bool?
    getter workspace : Int32?
    getter clear : Field
    getter? stop : Bool

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
    getter matcher : Matcher
    getter action : Action
    getter priority : Int32

    def initialize(@matcher : Matcher, @action : Action, @priority : Int32 = 0)
    end
  end

  struct Resolution
    getter target : String?
    getter? focus : Bool
    getter workspace : Int32?
    getter matched : Array(Int32)

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
    getter window : Window
    getter previous : Rect
    getter rect : Rect
    getter? was_visible : Bool
    getter? visible : Bool

    def initialize(@window : Window, @previous : Rect, @rect : Rect,
                   @was_visible : Bool, @visible : Bool)
    end

    def moved? : Bool
      previous != rect
    end

    def visibility_changed? : Bool
      was_visible? != visible?
    end
  end

  class Scratchpad
    getter name : String
    property window_id : Int32?
    property? shown : Bool
    property width : Int32
    property height : Int32

    def initialize(@name : String, @window_id : Int32? = nil,
                   @shown : Bool = false, @width : Int32 = 0, @height : Int32 = 0)
    end

    def bound? : Bool
      !window_id.nil?
    end
  end

  class Engine
    getter screen : Screen
    property rules : Array(Rule)
    property default_stack : String
    property direction : Direction
    getter workspaces : Array(Workspace)
    getter active : Int32
    getter scratchpads : Hash(String, Scratchpad)
    getter last_resolution : Resolution?
    getter changes : Array(Change)
    getter? dirty : Bool

    def initialize(@screen : Screen = Screen.new, @rules : Array(Rule) = [] of Rule,
                   @default_stack : String = "main",
                   @direction : Direction = Direction::Horizontal,
                   workspaces : Int32 = 1)
      @next_id = 0
      @active = 0
      @last_resolution = nil
      @dirty = true
      @changes = [] of Change
      @snapshot = [] of Tuple(Window, Rect, Bool)
      @buffer = [] of Window
      @scratchpads = {} of String => Scratchpad
      count = workspaces > 0 ? workspaces : 1
      @workspaces = Array(Workspace).new(count)
      count.times { @workspaces << Workspace.new(next_id, direction: @direction) }
    end

    def current : Workspace
      @workspaces[@active]
    end

    def workspace(index : Int32) : Workspace?
      @workspaces[index]?
    end

    def focused : Int32?
      current.focused
    end

    def fullscreen : Int32?
      current.fullscreen
    end

    def screen=(screen : Screen) : Screen
      @screen = screen
      @dirty = true
      screen
    end

    def dirty! : Nil
      @dirty = true
    end

    def add_rule(rule : Rule) : Rule
      rules << rule
      rule
    end

    def add_workspace(name : String? = nil, direction : Direction = @direction) : Workspace
      created = Workspace.new(next_id, name, direction)
      @workspaces << created
      created
    end

    def switch_workspace(index : Int32) : Status
      return Status::Missing if index < 0 || index >= @workspaces.size
      return Status::Unchanged if index == @active
      @active = index
      @dirty = true
      Status::Changed
    end

    def switch_next : Status
      switch_workspace((@active + 1) % @workspaces.size)
    end

    def switch_prev : Status
      switch_workspace((@active - 1) % @workspaces.size)
    end

    def resize_screen(cols : Int32, rows : Int32) : Status
      return Status::Unchanged if screen.cols == cols && screen.rows == rows
      screen.cols = cols
      screen.rows = rows
      @dirty = true
      Status::Changed
    end

    def register(app_id : String, title : String, tag : String? = nil,
                 parent : Int32? = nil) : Window
      window = Window.new(next_id, app_id, title, tag, parent: parent)
      resolution = resolve_into(window)
      ws = resolution.workspace.try { |index| workspace(index) } || current
      bind_scratchpad(window)
      place(ws, window, resolution.target, resolution.focus?)
      focus_in(ws, window.id) if resolution.focus?
      @dirty = true
      window
    end

    def unregister(window_id : Int32) : Window?
      located = locate(window_id)
      return nil unless located
      ws, window = located
      cascade_modals(window)
      replacement = ws.focused == window_id ? successor(ws, window) : nil
      detach(ws, window)
      release_scratchpad(window)
      ws.fullscreen = nil if ws.fullscreen == window_id
      prune(ws)
      if ws.focused == window_id
        ws.focused = replacement.try(&.id)
        resync(ws)
      end
      @dirty = true
      window
    end

    def update(window : Window) : Status
      located = locate(window.id)
      return Status::Missing unless located
      ws, _ = located
      resolution = resolve_into(window)
      target_ws = resolution.workspace.try { |index| workspace(index) } || ws
      detach(ws, window)
      bind_scratchpad(window)
      place(target_ws, window, resolution.target, resolution.focus?)
      prune(ws)
      focus_in(target_ws, window.id) if resolution.focus?
      resync(target_ws)
      @dirty = true
      Status::Changed
    end

    def apply(force : Bool = false) : Array(Change)
      @changes.clear
      return @changes unless @dirty || force
      validate_focus
      @workspaces.each { |ws| prune(ws) }
      capture
      layout_screen
      diff
      @dirty = false
      @changes
    end

    def window(window_id : Int32) : Window?
      located = locate(window_id)
      located.try { |(_, window)| window }
    end

    def windows : Array(Window)
      collect_all([] of Window)
    end

    def visible_windows : Array(Window)
      result = [] of Window
      collect_current(result)
      result.select! { |window| window.visible? }
      result
    end

    def render_order : Array(Window)
      result = [] of Window
      ws = current
      screen.background.windows.each { |window| result << window }
      if root = ws.tiled.root
        collect_render(root, result)
      end
      ws.floating.windows.each { |window| result << window }
      screen.sticky.windows.each { |window| result << window }
      ws.overlay.windows.each { |window| result << window }
      result
    end

    def focus_order : Array(Window)
      collect_current([] of Window)
    end

    def stack(name : String) : Stack?
      root = current.tiled.root
      return nil unless root
      find_named(root, name)
    end

    def node(id : Int32) : Node?
      root = current.tiled.root
      return nil unless root
      find_node(root, id)
    end

    def window_at(x : Int32, y : Int32) : Window?
      ws = current
      if (window = topmost_at(ws.overlay, x, y))
        return window
      end
      if (window = topmost_at(screen.sticky, x, y))
        return window
      end
      if (window = topmost_at(ws.floating, x, y))
        return window
      end
      if root = ws.tiled.root
        found = window_at_in(root, x, y)
        return found if found
      end
      topmost_at(screen.background, x, y)
    end

    def create_stack(name : String? = nil, sizing : Sizing = Sizing.new,
                     near : Stack? = nil, direction : Direction = @direction) : Stack
      create_stack_in(current, name, sizing, near, direction)
    end

    def move(window_id : Int32, to : String, activate : Bool = false) : Status
      located = locate(window_id)
      return Status::Missing unless located
      ws, target = located
      return Status::Rejected unless target.layer.tiled?
      owner = owning_stack(ws, window_id)
      return Status::Unchanged if owner && owner.name == to
      detach(ws, target)
      place(ws, target, to, activate)
      prune(ws)
      focus_in(ws, window_id) if activate
      resync(ws)
      @dirty = true
      Status::Changed
    end

    def move_to_workspace(window_id : Int32, index : Int32,
                          activate : Bool = false) : Status
      return Status::Missing if index < 0 || index >= @workspaces.size
      located = locate(window_id)
      return Status::Missing unless located
      source, target = located
      destination = @workspaces[index]
      return Status::Unchanged if source.same_ref?(destination)
      followed = source.focused == window_id
      detach(source, target)
      prune(source)
      place(destination, target, nil, activate)
      if followed
        source.focused = successor_id(source)
        resync(source)
      end
      focus_in(destination, window_id) if activate
      @dirty = true
      Status::Changed
    end

    def retag(window_id : Int32, tag : String?) : Status
      target = window(window_id)
      return Status::Missing unless target
      return Status::Unchanged if target.tag == tag
      target.tag = tag
      update(target)
    end

    def move_by_tag(tag : String, to : String, activate : Bool = false) : Int32
      targets = [] of Window
      collect_current(targets)
      targets.select! { |window| window.tag == tag && window.layer.tiled? }
      moved = 0
      targets.each do |window|
        status = move(window.id, to, activate && moved == 0)
        moved += 1 if status.changed?
      end
      moved
    end

    def focus(window_id : Int32) : Status
      located = locate(window_id)
      return Status::Missing unless located
      ws, _ = located
      focus_in(ws, window_id)
    end

    def focused_window : Window?
      id = current.focused
      return nil unless id
      window(id)
    end

    def focus_next : Status
      cycle(1)
    end

    def focus_prev : Status
      cycle(-1)
    end

    def focus_stack_next : Status
      cycle_stack(1)
    end

    def focus_stack_prev : Status
      cycle_stack(-1)
    end

    def focus_left : Status
      focus_edge(Edge::Left)
    end

    def focus_right : Status
      focus_edge(Edge::Right)
    end

    def focus_up : Status
      focus_edge(Edge::Up)
    end

    def focus_down : Status
      focus_edge(Edge::Down)
    end

    def focus_edge(edge : Edge) : Status
      id = current.focused
      return Status::Missing unless id
      target = neighbor(id, edge)
      return Status::Rejected unless target
      focus(target.id)
    end

    def neighbor(window_id : Int32, edge : Edge) : Window?
      origin = window(window_id)
      return nil unless origin
      rect = origin.rect
      direction = edge.direction
      forward = edge.forward?
      best : Window? = nil
      best_score = {Int32::MAX, Int32::MAX, Int32::MAX}
      visible_windows.each do |candidate|
        next if candidate.same?(origin)
        other = candidate.rect
        distance =
          if direction.horizontal?
            forward ? other.x - rect.right : rect.x - other.right
          else
            forward ? other.y - rect.bottom : rect.y - other.bottom
          end
        next if distance < 0
        overlapping =
          if direction.horizontal?
            rect.y < other.bottom && other.y < rect.bottom
          else
            rect.x < other.right && other.x < rect.right
          end
        perpendicular =
          if direction.horizontal?
            (other.center_y - rect.center_y).abs
          else
            (other.center_x - rect.center_x).abs
          end
        score = {overlapping ? 0 : 1, distance, perpendicular}
        next unless score < best_score
        best_score = score
        best = candidate
      end
      best
    end

    def swap(first_id : Int32, second_id : Int32) : Status
      ws = current
      first = owning_stack(ws, first_id)
      second = owning_stack(ws, second_id)
      return Status::Missing unless first && second
      a = first.index_of(first_id)
      b = second.index_of(second_id)
      return Status::Missing unless a && b
      return Status::Unchanged if first.same?(second) && a == b
      moved = first.windows[a]
      first.windows[a] = second.windows[b]
      second.windows[b] = moved
      resync(ws)
      @dirty = true
      Status::Changed
    end

    def swap_nodes(first : Node, second : Node) : Status
      return Status::Unchanged if first.same?(second)
      ws = current
      first_parent = parent_split(ws, first)
      second_parent = parent_split(ws, second)
      return Status::Missing unless first_parent && second_parent
      return first_parent.swap(first, second) if first_parent.same?(second_parent)
      a = first_parent.index_of(first)
      b = second_parent.index_of(second)
      return Status::Missing unless a && b
      first_parent.children[a] = second
      second_parent.children[b] = first
      @dirty = true
      Status::Changed
    end

    def promote(window_id : Int32) : Status
      ws = current
      owner = owning_stack(ws, window_id)
      return Status::Missing unless owner
      promote_node(owner)
    end

    def promote_node(node : Node) : Status
      ws = current
      parent = parent_split(ws, node)
      return Status::Missing unless parent
      grandparent = parent_split(ws, parent)
      return Status::Rejected unless grandparent
      index = parent.index_of(node)
      destination = grandparent.index_of(parent)
      return Status::Missing unless index && destination
      parent.children.delete_at(index)
      grandparent.children.insert(destination, node)
      prune(ws)
      @dirty = true
      Status::Changed
    end

    def reorder_window(window_id : Int32, to : Int32) : Status
      owner = owning_stack(current, window_id)
      return Status::Missing unless owner
      status = owner.reorder(window_id, to)
      @dirty = true if status.changed?
      status
    end

    def reorder_node(node : Node, to : Int32) : Status
      parent = parent_split(current, node)
      return Status::Missing unless parent
      status = parent.reorder(node, to)
      @dirty = true if status.changed?
      status
    end

    def set_direction(node : Node, direction : Direction) : Status
      return Status::Rejected unless node.is_a?(Split)
      status = node.set_direction(direction)
      @dirty = true if status.changed?
      status
    end

    def toggle_direction(node : Node) : Status
      return Status::Rejected unless node.is_a?(Split)
      node.toggle_direction
      @dirty = true
      Status::Changed
    end

    def set_weight(node : Node, weight : Int32) : Status
      return Status::Unchanged if node.sizing.weight == weight
      node.sizing = node.sizing.with_weight(weight)
      @dirty = true
      Status::Changed
    end

    def set_fixed(node : Node, span : Int32?) : Status
      return Status::Unchanged if node.sizing.fixed == span
      node.sizing = node.sizing.with_fixed(span)
      @dirty = true
      Status::Changed
    end

    def set_min(node : Node, span : Int32?) : Status
      return Status::Unchanged if node.sizing.min == span
      node.sizing = node.sizing.with_min(span)
      @dirty = true
      Status::Changed
    end

    def set_max(node : Node, span : Int32?) : Status
      return Status::Unchanged if node.sizing.max == span
      node.sizing = node.sizing.with_max(span)
      @dirty = true
      Status::Changed
    end

    def resize_window(window_id : Int32, delta : Int32) : Status
      owner = owning_stack(current, window_id)
      return Status::Missing unless owner
      resize(owner, delta)
    end

    def resize(node : Node, delta : Int32) : Status
      return Status::Unchanged if delta == 0
      ws = current
      parent = parent_split(ws, node)
      return Status::Missing unless parent
      index = parent.index_of(node)
      return Status::Missing unless index
      peer_index = index + 1 < parent.children.size ? index + 1 : index - 1
      return Status::Rejected if peer_index < 0
      direction = parent.direction
      peer = parent.children[peer_index]
      span = node.rect.span(direction)
      total = span + peer.rect.span(direction)
      target = span + delta
      return Status::Rejected if total <= 0 || target <= 0 || target >= total
      normalize(parent, direction)
      assign_span(node, target)
      assign_span(peer, total - target)
      @dirty = true
      Status::Changed
    end

    def split(target : Stack, direction : Direction, app_id : String,
              title : String, tag : String? = nil, sizing : Sizing? = nil) : Stack
      ws = current
      window = Window.new(next_id, app_id, title, tag)
      resolution = resolve_into(window)
      window.layer = Layer::Tiled
      window.sizing = sizing if sizing
      pane = Stack.new(next_id, nil, sizing: window.sizing)
      split_with(ws, target, direction, pane)
      pane.add(window)
      focus_in(ws, window.id) if resolution.focus?
      @dirty = true
      pane
    end

    def toggle_fullscreen(window_id : Int32) : Status
      set_mode(window_id, Mode::Fullscreen)
    end

    def toggle_maximize(window_id : Int32) : Status
      set_mode(window_id, Mode::Maximized)
    end

    def set_mode(window_id : Int32, mode : Mode) : Status
      located = locate(window_id)
      return Status::Missing unless located
      ws, target = located
      if mode.fullscreen?
        ws.fullscreen = ws.fullscreen == window_id ? nil : window_id
      elsif ws.fullscreen == window_id
        ws.fullscreen = nil
      end
      target.mode = target.mode == mode ? Mode::Normal : mode
      @dirty = true
      Status::Changed
    end

    def bind_scratchpad(name : String, window_id : Int32,
                        width : Int32 = 0, height : Int32 = 0) : Scratchpad
      pad = @scratchpads[name] ||= Scratchpad.new(name)
      pad.window_id = window_id
      pad.width = width if width > 0
      pad.height = height if height > 0
      if target = window(window_id)
        target.scratchpad = name
        target.hidden = !pad.shown?
      end
      @dirty = true
      pad
    end

    def toggle_scratchpad(name : String) : Status
      pad = @scratchpads[name]?
      return Status::Missing unless pad
      id = pad.window_id
      return Status::Rejected unless id
      target = window(id)
      return Status::Missing unless target
      pad.shown = !pad.shown?
      target.hidden = !pad.shown?
      focus_in(current, id) if pad.shown?
      @dirty = true
      Status::Changed
    end

    def set_sticky(window_id : Int32, value : Bool) : Status
      located = locate(window_id)
      return Status::Missing unless located
      ws, target = located
      return Status::Rejected if target.layer.tiled?
      return Status::Unchanged if target.sticky? == value
      detach(ws, target)
      target.sticky = value
      if value
        screen.sticky.add(target)
      else
        (ws.stacked(target.layer) || ws.floating).add(target)
      end
      @dirty = true
      Status::Changed
    end

    def toggle_sticky(window_id : Int32) : Status
      target = window(window_id)
      return Status::Missing unless target
      set_sticky(window_id, !target.sticky?)
    end

    def raise(window_id : Int32) : Status
      z_order(window_id) { |layer, window| layer.raise(window) }
    end

    def lower(window_id : Int32) : Status
      z_order(window_id) { |layer, window| layer.lower(window) }
    end

    def raise_to_top(window_id : Int32) : Status
      z_order(window_id) { |layer, window| layer.raise_to_top(window) }
    end

    def lower_to_bottom(window_id : Int32) : Status
      z_order(window_id) { |layer, window| layer.lower_to_bottom(window) }
    end

    private def next_id : Int32
      id = @next_id
      @next_id += 1
      id
    end

    private def resolve_into(window : Window) : Resolution
      resolution = resolve(window)
      @last_resolution = resolution
      resolution
    end

    private def resolve(window : Window) : Resolution
      matched = [] of Int32
      rules.each_with_index do |rule, index|
        matched << index if rule.matcher.matches?(window)
      end
      return Resolution.new(nil, false, nil, matched) if matched.empty?
      matched.sort_by! { |index| {rules[index].priority, index} }
      target = nil
      activate = false
      destination = nil
      matched.each do |index|
        action = rules[index].action
        clear = action.clear
        target = nil if clear.stack?
        activate = false if clear.focus?
        destination = nil if clear.workspace?
        apply_action(window, action)
        if stack = action.stack
          target = stack
        end
        if value = action.focus
          activate = value
        end
        if ws = action.workspace
          destination = ws
        end
        break if action.stop?
      end
      Resolution.new(target, activate, destination, matched)
    end

    private def apply_action(window : Window, action : Action) : Nil
      clear = action.clear
      window.layer = Layer::Tiled if clear.layer?
      window.strut = nil if clear.strut?
      window.scratchpad = nil if clear.scratchpad?
      window.sticky = false if clear.sticky?
      if layer = action.layer
        window.layer = layer
      end
      if strut = action.strut
        window.strut = strut
      end
      if scratchpad = action.scratchpad
        window.scratchpad = scratchpad
      end
      if sticky = action.sticky
        window.sticky = sticky
      end
      sizing = window.sizing
      sizing = sizing.with_weight(1) if clear.weight?
      sizing = sizing.with_fixed(nil) if clear.fixed?
      sizing = sizing.with_min(nil) if clear.min?
      sizing = sizing.with_max(nil) if clear.max?
      if weight = action.weight
        sizing = sizing.with_weight(weight)
      end
      if fixed = action.fixed
        sizing = sizing.with_fixed(fixed)
      end
      if min = action.min
        sizing = sizing.with_min(min)
      end
      if max = action.max
        sizing = sizing.with_max(max)
      end
      window.sizing = sizing
    end

    private def bind_scratchpad(window : Window) : Nil
      name = window.scratchpad
      return unless name
      pad = @scratchpads[name] ||= Scratchpad.new(name)
      pad.window_id = window.id
      window.hidden = !pad.shown?
      window.layer = Layer::Floating if window.layer.tiled?
    end

    private def release_scratchpad(window : Window) : Nil
      name = window.scratchpad
      return unless name
      pad = @scratchpads[name]?
      return unless pad
      pad.window_id = nil if pad.window_id == window.id
    end

    private def place(ws : Workspace, window : Window, target : String? = nil,
                      activate : Bool = false) : Nil
      if window.sticky? && !window.layer.tiled?
        screen.sticky.add(window)
        return
      end
      case window.layer
      when Layer::Tiled
        name = target || @default_stack
        destination = find_named_in(ws, name) || create_stack_in(ws, name, window.sizing)
        destination.add(window)
        destination.focus(window.id) if activate
      when Layer::Background
        screen.background.add(window)
      else
        stacked = ws.stacked(window.layer) || ws.floating
        stacked.add(window)
      end
    end

    private def create_stack_in(ws : Workspace, name : String? = nil,
                                sizing : Sizing = Sizing.new, near : Stack? = nil,
                                direction : Direction = @direction) : Stack
      created = Stack.new(next_id, name, sizing: sizing)
      if near
        split_with(ws, near, direction, created)
      else
        attach(ws, created, direction)
      end
      @dirty = true
      created
    end

    private def attach(ws : Workspace, created : Stack, direction : Direction) : Nil
      tiled = ws.tiled
      root = tiled.root
      case root
      in Nil
        tiled.root = created
      in Stack
        tiled.root = Split.new(next_id, direction, [root.as(Node), created.as(Node)])
      in Split
        if root.direction == direction
          root.children << created.as(Node)
        else
          tiled.root = Split.new(next_id, direction, [root.as(Node), created.as(Node)])
        end
      end
    end

    private def split_with(ws : Workspace, target : Stack, direction : Direction,
                           pane : Stack) : Split
      wrapper = Split.new(next_id, direction, sizing: target.sizing)
      tiled = ws.tiled
      root = tiled.root
      if root.nil? || root.same?(target)
        tiled.root = wrapper
      else
        replace_child(root, target, wrapper)
      end
      wrapper.children << target.as(Node)
      wrapper.children << pane.as(Node)
      wrapper
    end

    private def detach(ws : Workspace, window : Window) : Bool
      removed = false
      if root = ws.tiled.root
        removed = true if detach_from(root, window)
      end
      removed = true if ws.floating.remove(window)
      removed = true if ws.overlay.remove(window)
      removed = true if screen.sticky.remove(window)
      removed = true if screen.background.remove(window)
      removed
    end

    private def detach_from(node : Node, window : Window) : Bool
      case node
      in Stack
        !node.remove(window.id).nil?
      in Split
        removed = false
        node.children.each do |child|
          removed = true if detach_from(child, window)
        end
        removed
      end
    end

    private def cascade_modals(window : Window) : Nil
      children = [] of Window
      collect_all(children)
      children.each do |candidate|
        next unless candidate.parent == window.id
        unregister(candidate.id)
      end
    end

    private def successor(ws : Workspace, window : Window) : Window?
      order = collect_workspace_owned(ws, [] of Window)
      index = order.index { |candidate| candidate.same?(window) }
      return nil unless index
      return nil if order.size <= 1
      order[(index + 1) % order.size]
    end

    private def successor_id(ws : Workspace) : Int32?
      order = collect_workspace_owned(ws, [] of Window)
      order.first?.try(&.id)
    end

    private def validate_focus : Nil
      @workspaces.each do |ws|
        id = ws.focused
        next unless id
        ws.focused = nil unless locate(id)
      end
    end

    private def resync(ws : Workspace) : Nil
      id = ws.focused
      return unless id
      if owner = owning_stack(ws, id)
        owner.focus(id)
      end
    end

    private def focus_in(ws : Workspace, window_id : Int32) : Status
      changed = ws.focused != window_id
      ws.focused = window_id
      if owner = owning_stack(ws, window_id)
        changed = true if owner.focus(window_id).changed?
      end
      @dirty = true if changed
      changed ? Status::Changed : Status::Unchanged
    end

    private def cycle(step : Int32) : Status
      ws = current
      order = collect_workspace_owned(ws, [] of Window)
      return Status::Missing if order.empty?
      current_id = ws.focused
      index = current_id ? order.index { |window| window.id == current_id } : nil
      destination =
        if index
          (index + step) % order.size
        else
          step > 0 ? 0 : order.size - 1
        end
      focus_in(ws, order[destination].id)
    end

    private def cycle_stack(step : Int32) : Status
      ws = current
      id = ws.focused
      return Status::Missing unless id
      owner = owning_stack(ws, id)
      return Status::Missing unless owner
      status = step > 0 ? owner.focus_next : owner.focus_prev
      return status unless status.changed?
      active = owner.active_window
      return Status::Rejected unless active
      ws.focused = active.id
      @dirty = true
      Status::Changed
    end

    private def z_order(window_id : Int32, & : StackedLayer, Window -> Status) : Status
      located = locate(window_id)
      return Status::Missing unless located
      ws, target = located
      return Status::Rejected if target.layer.tiled?
      stacked =
        if target.sticky?
          screen.sticky
        else
          ws.stacked(target.layer) || (target.layer.background? ? screen.background : nil)
        end
      return Status::Rejected unless stacked
      return Status::Missing unless stacked.index_of(target)
      status = yield stacked, target
      @dirty = true if status.changed?
      status
    end

    private def locate(window_id : Int32) : Tuple(Workspace, Window)?
      if window = screen.sticky.windows.find { |candidate| candidate.id == window_id }
        return {current, window}
      end
      if window = screen.background.windows.find { |candidate| candidate.id == window_id }
        return {current, window}
      end
      @workspaces.each do |ws|
        if root = ws.tiled.root
          if window = find_window_in(root, window_id)
            return {ws, window}
          end
        end
        if window = ws.floating.windows.find { |candidate| candidate.id == window_id }
          return {ws, window}
        end
        if window = ws.overlay.windows.find { |candidate| candidate.id == window_id }
          return {ws, window}
        end
      end
      nil
    end

    private def collect_all(into : Array(Window)) : Array(Window)
      screen.background.windows.each { |window| into << window }
      screen.sticky.windows.each { |window| into << window }
      @workspaces.each do |ws|
        if root = ws.tiled.root
          collect_windows(root, into)
        end
        ws.floating.windows.each { |window| into << window }
        ws.overlay.windows.each { |window| into << window }
      end
      into
    end

    private def collect_current(into : Array(Window)) : Array(Window)
      collect_workspace(current, into)
    end

    private def collect_workspace(ws : Workspace, into : Array(Window)) : Array(Window)
      collect_workspace_owned(ws, into)
      screen.sticky.windows.each { |window| into << window }
      into
    end

    private def collect_workspace_owned(ws : Workspace, into : Array(Window)) : Array(Window)
      if root = ws.tiled.root
        collect_windows(root, into)
      end
      ws.floating.windows.each { |window| into << window }
      ws.overlay.windows.each { |window| into << window }
      into
    end

    private def collect_windows(node : Node, into : Array(Window)) : Nil
      case node
      in Stack
        node.windows.each { |window| into << window }
      in Split
        node.children.each { |child| collect_windows(child, into) }
      end
    end

    private def collect_render(node : Node, into : Array(Window)) : Nil
      case node
      in Stack
        active = node.active_window
        node.windows.each do |window|
          into << window unless active && window.same?(active)
        end
        into << active if active
      in Split
        node.children.each { |child| collect_render(child, into) }
      end
    end

    private def owning_stack(ws : Workspace, window_id : Int32) : Stack?
      root = ws.tiled.root
      return nil unless root
      owning_stack_in(root, window_id)
    end

    private def owning_stack_in(node : Node, window_id : Int32) : Stack?
      case node
      in Stack
        node.index_of(window_id) ? node : nil
      in Split
        node.children.each do |child|
          found = owning_stack_in(child, window_id)
          return found if found
        end
        nil
      end
    end

    private def parent_split(ws : Workspace, node : Node) : Split?
      root = ws.tiled.root
      return nil unless root
      return nil if root.same?(node)
      find_parent(root, node)
    end

    private def find_parent(current : Node, node : Node) : Split?
      case current
      in Stack
        nil
      in Split
        current.children.each do |child|
          return current if child.same?(node)
          found = find_parent(child, node)
          return found if found
        end
        nil
      end
    end

    private def find_window_in(node : Node, window_id : Int32) : Window?
      case node
      in Stack
        node.windows.find { |window| window.id == window_id }
      in Split
        node.children.each do |child|
          found = find_window_in(child, window_id)
          return found if found
        end
        nil
      end
    end

    private def find_named(node : Node, name : String) : Stack?
      case node
      in Stack
        node.name == name ? node : nil
      in Split
        node.children.each do |child|
          found = find_named(child, name)
          return found if found
        end
        nil
      end
    end

    private def find_named_in(ws : Workspace, name : String) : Stack?
      root = ws.tiled.root
      return nil unless root
      find_named(root, name)
    end

    private def find_node(node : Node, id : Int32) : Node?
      return node if node.id == id
      case node
      in Stack
        nil
      in Split
        node.children.each do |child|
          found = find_node(child, id)
          return found if found
        end
        nil
      end
    end

    private def topmost_at(layer : StackedLayer, x : Int32, y : Int32) : Window?
      candidates = layer.windows
      position = candidates.size - 1
      while position >= 0
        window = candidates[position]
        return window if window.visible? && window.rect.contains?(x, y)
        position -= 1
      end
      nil
    end

    private def window_at_in(node : Node, x : Int32, y : Int32) : Window?
      return nil unless node.rect.contains?(x, y)
      case node
      in Stack
        active = node.active_window
        active && active.visible? ? active : nil
      in Split
        node.children.each do |child|
          found = window_at_in(child, x, y)
          return found if found
        end
        nil
      end
    end

    private def replace_child(node : Node, target : Stack, replacement : Node) : Bool
      case node
      in Stack
        false
      in Split
        node.children.each_with_index do |child, index|
          if child.same?(target)
            node.children[index] = replacement
            return true
          end
          return true if replace_child(child, target, replacement)
        end
        false
      end
    end

    private def prune(ws : Workspace) : Nil
      tiled = ws.tiled
      root = tiled.root
      return unless root
      tiled.root = prune_node(root)
    end

    private def prune_node(node : Node) : Node?
      case node
      in Stack
        node.empty? ? nil : node
      in Split
        children = node.children
        write = 0
        children.each do |child|
          pruned = prune_node(child)
          next unless pruned
          children[write] = pruned
          write += 1
        end
        while children.size > write
          children.pop
        end
        case children.size
        when 0
          nil
        when 1
          node.promote
        else
          node
        end
      end
    end

    private def normalize(parent : Split, direction : Direction) : Nil
      parent.children.each do |child|
        next if child.sizing.fixed?
        span = child.rect.span(direction)
        child.sizing = child.sizing.with_weight(span > 0 ? span : 1)
      end
    end

    private def assign_span(node : Node, span : Int32) : Nil
      sizing = node.sizing
      if sizing.fixed?
        node.sizing = sizing.with_fixed(span)
      else
        node.sizing = sizing.with_weight(span > 0 ? span : 1)
      end
    end

    private def layout_screen : Nil
      ws = current
      bounds = screen.bounds
      area = work_area(ws, bounds)

      screen.background.windows.each { |window| clamp(window, bounds) }
      layout_panels(ws, bounds)

      if (id = ws.fullscreen) && (target = window(id)) && !target.hidden?
        layout_fullscreen(ws, target, bounds, area)
      else
        if root = ws.tiled.root
          layout(root, area)
        end
        layout_floating(ws, area)
      end

      hide_inactive(ws)
    end

    private def work_area(ws : Workspace, bounds : Rect) : Rect
      top = 0
      bottom = 0
      left = 0
      right = 0
      each_panel(ws) do |window, strut|
        case strut.side
        in Side::Top    then top += strut.size
        in Side::Bottom then bottom += strut.size
        in Side::Left   then left += strut.size
        in Side::Right  then right += strut.size
        end
      end
      bounds.inset(left, top, right, bottom)
    end

    private def layout_panels(ws : Workspace, bounds : Rect) : Nil
      top = bounds.y
      bottom = bounds.bottom
      left = bounds.x
      right = bounds.right
      each_panel(ws) do |window, strut|
        rect =
          case strut.side
          in Side::Top
            band = Rect.new(bounds.x, top, bounds.cols, strut.size)
            top += strut.size
            band
          in Side::Bottom
            bottom -= strut.size
            Rect.new(bounds.x, bottom, bounds.cols, strut.size)
          in Side::Left
            band = Rect.new(left, bounds.y, strut.size, bounds.rows)
            left += strut.size
            band
          in Side::Right
            right -= strut.size
            Rect.new(right, bounds.y, strut.size, bounds.rows)
          end
        place_window(window, rect, !rect.empty?)
      end
    end

    private def each_panel(ws : Workspace, & : Window, Strut ->) : Nil
      ws.overlay.windows.each do |window|
        next if window.hidden?
        if strut = window.strut
          yield window, strut if strut.active?
        end
      end
    end

    private def layout_fullscreen(ws : Workspace, target : Window,
                                  bounds : Rect, area : Rect) : Nil
      rect = target.mode.maximized? ? area : bounds
      place_window(target, rect, true)
      hidden = [] of Window
      collect_workspace(ws, hidden)
      hidden.each do |window|
        next if window.same?(target)
        next if window.panel?
        place_window(window, window.rect, false)
      end
    end

    private def layout_floating(ws : Workspace, area : Rect) : Nil
      layout_stacked(ws.floating, area)
      layout_stacked(screen.sticky, area)
      layout_overlay(ws, area)
    end

    private def layout_overlay(ws : Workspace, area : Rect) : Nil
      ws.overlay.windows.each do |window|
        next if window.panel?
        anchor_floating(window, area)
      end
    end

    private def layout_stacked(layer : StackedLayer, area : Rect) : Nil
      layer.windows.each { |window| anchor_floating(window, area) }
    end

    private def anchor_floating(window : Window, area : Rect) : Nil
      if window.hidden?
        place_window(window, window.rect, false)
        return
      end
      case window.mode
      when .fullscreen?
        place_window(window, screen.bounds, true)
        return
      when .maximized?
        place_window(window, area, true)
        return
      end
      if window.scratchpad?
        rect = scratchpad_rect(window, area)
        place_window(window, rect, !rect.empty?)
        return
      end
      if parent_id = window.parent
        if parent = window(parent_id)
          rect = area.centered(window.rect.cols, window.rect.rows)
          rect = parent.rect.centered(window.rect.cols, window.rect.rows) unless parent.rect.empty?
          place_window(window, rect, !rect.empty?)
          return
        end
      end
      if window.rect.empty?
        window.rect = area.centered(area.cols // 2, area.rows // 2)
      end
      clamp(window, area)
    end

    private def scratchpad_rect(window : Window, area : Rect) : Rect
      name = window.scratchpad
      pad = name ? @scratchpads[name]? : nil
      width = pad && pad.width > 0 ? pad.width : (window.rect.cols > 0 ? window.rect.cols : area.cols // 2)
      height = pad && pad.height > 0 ? pad.height : (window.rect.rows > 0 ? window.rect.rows : area.rows // 2)
      area.centered(width, height)
    end

    private def hide_inactive(ws : Workspace) : Nil
      @workspaces.each do |other|
        next if other.same_ref?(ws)
        hidden = [] of Window
        collect_workspace_owned(other, hidden)
        hidden.each do |window|
          place_window(window, window.rect, false)
        end
      end
    end

    private def clamp(window : Window, area : Rect) : Nil
      if window.hidden?
        place_window(window, window.rect, false)
        return
      end
      rect = window.rect
      max_cols = area.cols > 0 ? area.cols : 0
      max_rows = area.rows > 0 ? area.rows : 0
      cols = rect.cols.clamp(0, max_cols)
      rows = rect.rows.clamp(0, max_rows)
      x = rect.x.clamp(area.x, area.right - cols > area.x ? area.right - cols : area.x)
      y = rect.y.clamp(area.y, area.bottom - rows > area.y ? area.bottom - rows : area.y)
      bounded = Rect.new(x, y, cols, rows)
      place_window(window, bounded, !bounded.empty?)
    end

    private def place_window(window : Window, rect : Rect, visible : Bool) : Nil
      cell = screen.cell
      window.rect = rect
      window.visible = visible
      window.pixel = PixelRect.new(rect.x * cell.width, rect.y * cell.height,
        rect.cols * cell.width, rect.rows * cell.height)
    end

    private def layout(node : Node, rect : Rect) : Nil
      case node
      in Stack
        node.rect = rect
        content = node.content_rect
        visible = !content.empty?
        node.windows.each_with_index do |window, index|
          place_window(window, content, visible && index == node.active)
        end
      in Split
        node.rect = rect
        partition(node, rect)
      end
    end

    private def partition(split : Split, rect : Rect) : Nil
      children = split.children
      return if children.empty?
      direction = split.direction
      spans = distribute(children, rect.span(direction))
      offset = rect.offset(direction)
      children.each_with_index do |child, index|
        span = spans[index]
        layout(child, rect.slice(direction, offset, span))
        offset += span
      end
    end

    private def distribute(children : Array(Node), total : Int32) : Array(Int32)
      count = children.size
      spans = Array(Int32).new(count, 0)
      settled = Array(Bool).new(count, false)
      remaining = total > 0 ? total : 0
      flexible = 0

      count.times do |index|
        sizing = children[index].sizing
        if fixed = sizing.fixed
          span = sizing.clamp_span(fixed)
          span = 0 if span < 0
          span = remaining if span > remaining
          spans[index] = span
          settled[index] = true
          remaining -= span
        else
          flexible += 1
        end
      end

      while flexible > 0
        weight_sum = 0
        last = -1
        count.times do |index|
          next if settled[index]
          weight_sum += children[index].sizing.weight
          last = index
        end
        break if weight_sum <= 0 || last < 0

        clamped = false
        accumulated = 0
        count.times do |index|
          next if settled[index]
          sizing = children[index].sizing
          raw =
            if index == last
              remaining - accumulated
            else
              remaining * sizing.weight // weight_sum
            end
          accumulated += raw unless index == last
          bounded = sizing.clamp_span(raw)
          next if bounded == raw
          bounded = 0 if bounded < 0
          bounded = remaining if bounded > remaining
          spans[index] = bounded
          settled[index] = true
          flexible -= 1
          remaining -= bounded
          clamped = true
          break
        end
        next if clamped

        accumulated = 0
        count.times do |index|
          next if settled[index]
          sizing = children[index].sizing
          span =
            if index == last
              remaining - accumulated
            else
              remaining * sizing.weight // weight_sum
            end
          accumulated += span
          spans[index] = span
          settled[index] = true
          flexible -= 1
        end
        remaining = 0
      end

      remaining = absorb(children, spans, remaining, true)
      absorb(children, spans, remaining, false)
      spans
    end

    private def absorb(children : Array(Node), spans : Array(Int32),
                       remaining : Int32, skip_fixed : Bool) : Int32
      index = children.size - 1
      while index >= 0 && remaining > 0
        sizing = children[index].sizing
        unless skip_fixed && sizing.fixed?
          room = remaining
          if high = sizing.max
            available = high - spans[index]
            room = available < remaining ? available : remaining
          end
          if room > 0
            spans[index] += room
            remaining -= room
          end
        end
        index -= 1
      end
      remaining
    end

    private def capture : Nil
      @snapshot.clear
      @buffer.clear
      collect_all(@buffer)
      @buffer.each { |window| @snapshot << {window, window.rect, window.visible?} }
    end

    private def diff : Nil
      @snapshot.each do |entry|
        window, rect, visible = entry
        next if window.rect == rect && window.visible? == visible
        @changes << Change.new(window, rect, window.rect, visible, window.visible?)
      end
    end
  end

  class Runtime
    alias Intent = Engine ->

    CONTEXT_NAME = "asekii:layout"
    INTENT_CAP   = 256
    FRAME_CAP    =  64

    enum Phase
      Idle
      Running
      Closed
    end

    getter frames : Channel(Array(Change))

    @engine : Engine
    @intents : Channel(Intent)
    @phase : Atomic(Phase)
    @context : Fiber::ExecutionContext::Isolated?

    def initialize(@engine : Engine = Engine.new,
                   intent_cap : Int32 = INTENT_CAP, frame_cap : Int32 = FRAME_CAP)
      @intents = Channel(Intent).new(intent_cap)
      @frames = Channel(Array(Change)).new(frame_cap)
      @phase = Atomic(Phase).new(Phase::Idle)
      @context = nil
    end

    def phase : Phase
      @phase.get
    end

    def running? : Bool
      @phase.get.running?
    end

    def closed? : Bool
      @phase.get.closed?
    end

    def start : Nil
      return unless @phase.compare_and_set(Phase::Idle, Phase::Running)[1]
      @context = Fiber::ExecutionContext::Isolated.new(CONTEXT_NAME) { run }
    end

    def stop : Nil
      return if @phase.get.closed?
      @intents.close
      wait
      @phase.set(Phase::Closed)
    end

    def wait : Nil
      @context.try(&.wait)
    end

    def submit(intent : Intent) : Bool
      @intents.send(intent)
      true
    rescue Channel::ClosedError
      false
    end

    def submit(&intent : Intent) : Bool
      submit(intent)
    end

    def resize(cols : Int32, rows : Int32, cell_width : Int32 = 0,
               cell_height : Int32 = 0) : Bool
      submit do |engine|
        if cell_width > 0 && cell_height > 0
          engine.screen.cell = CellSize.new(cell_width, cell_height)
          engine.dirty!
        end
        engine.resize_screen(cols, rows)
      end
    end

    def refresh : Bool
      submit(&.dirty!)
    end

    private def run : Nil
      loop do
        intent = @intents.receive?
        break if intent.nil?

        intent.call(@engine)
        break unless drain
        emit
      end
    ensure
      @phase.set(Phase::Closed)
      @frames.close
    end

    private def drain : Bool
      loop do
        select
        when intent = @intents.receive?
          return false if intent.nil?
          intent.call(@engine)
        else
          return true
        end
      end
    end

    private def emit : Nil
      changes = @engine.apply
      return if changes.empty?
      @frames.send(changes.dup)
    rescue Channel::ClosedError
    end
  end
end
