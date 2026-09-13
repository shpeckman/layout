# examples/support.cr
require "../src/layout"

include Layout

module Example
  extend self

  GLYPHS = "abcdefghijklmnopqrstuvwxyz"
  BLANK  = '.'

  def title(text : String) : Nil
    puts
    puts text
    puts "=" * text.size
  end

  def step(text : String) : Nil
    puts
    puts "-- #{text}"
  end

  def line(text : String) : Nil
    puts "   #{text}"
  end

  def status(label : String, value : Status) : Nil
    line("#{label.ljust(26)} #{value}")
  end

  def area(rect : Rect) : String
    "#{rect.cols.to_s.rjust(3)}x#{rect.rows.to_s.rjust(2)}+#{rect.x.to_s.rjust(3)}+#{rect.y.to_s.rjust(2)}"
  end

  def glyph(window : Window) : Char
    GLYPHS[window.id % GLYPHS.size]
  end

  def state(window : Window) : String
    return "hidden" if window.hidden?
    window.visible? ? "shown" : "off"
  end

  def describe(engine : Engine, window : Window) : String
    String.build do |io|
      io << (engine.focused == window.id ? '*' : ' ')
      io << glyph(window)
      io << " #" << window.id.to_s.ljust(3)
      io << window.app_id.ljust(14)
      io << window.layer.to_s.ljust(11)
      io << state(window).ljust(8)
      io << area(window.rect)
      if tag = window.tag
        io << "  tag=" << tag
      end
    end
  end

  def windows(engine : Engine) : Nil
    engine.windows.each { |window| line(describe(engine, window)) }
  end

  def legend(engine : Engine) : Nil
    engine.windows.each do |window|
      next unless window.visible?
      line("#{glyph(window)} = #{window.title}")
    end
  end

  def canvas(engine : Engine) : Nil
    screen = engine.screen
    return if screen.cols <= 0 || screen.rows <= 0
    bounds = screen.bounds
    buffer = Array(Array(Char)).new(screen.rows) { Array(Char).new(screen.cols, BLANK) }
    engine.render_order.each do |window|
      next unless window.visible?
      mark = glyph(window)
      rect = window.rect
      row  = rect.y - bounds.y
      rect.rows.times do
        if row >= 0 && row < screen.rows
          scanline = buffer[row]
          column   = rect.x - bounds.x
          rect.cols.times do
            scanline[column] = mark if column >= 0 && column < screen.cols
            column += 1
          end
        end
        row += 1
      end
    end
    buffer.each { |scanline| puts "   #{scanline.join}" }
  end

  def kind(change : Change) : String
    return "appeared" if change.appeared?
    return "vanished" if change.vanished?
    change.moved? ? "moved" : "restacked"
  end

  def changes(list : Array(Change)) : Nil
    if list.empty?
      line("no changes")
      return
    end
    list.each do |change|
      line("##{change.id.to_s.ljust(3)} #{kind(change).ljust(10)} #{area(change.previous)} -> #{area(change.rect)}")
    end
  end

  def tree(engine : Engine) : Nil
    if root = engine.current.tiled.root
      line("Workspace #{engine.active}")
      tree_node(root, "   ", true)
    else
      line("Workspace #{engine.active} (Empty)")
    end
  end

  def tree_node(node : Node, prefix : String, is_last : Bool) : Nil
    marker = is_last ? "└── " : "├── "
    child_prefix = prefix + (is_last ? "    " : "│   ")

    case node
    in Split
      puts "#{prefix}#{marker}Split(#{node.direction})"
      node.children.each_with_index do |child, index|
        tree_node(child, child_prefix, index == node.children.size - 1)
      end
    in Stack
      puts "#{prefix}#{marker}Stack(#{node.name || "unnamed"})"
      node.windows.each_with_index do |window, index|
        win_marker = index == node.size - 1 ? "└── " : "├── "
        active = node.active_window.try(&.same?(window)) ? "*" : " "
        puts "#{child_prefix}#{win_marker}#{active}[#{window.id}] #{window.title}"
      end
    end
  end
end

