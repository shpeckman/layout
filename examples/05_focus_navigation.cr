# examples/05_focus_navigation.cr
require "./support"

engine = Engine.new(Screen.new(80, 20), default_stack: "top-left")

top_left  = engine.create_stack("top-left")
top_right = engine.create_stack("top-right", near: top_left, direction: Direction::Horizontal)

editor  = engine.register("nvim", "editor")
browser = engine.register("firefox", "browser")
engine.move(browser.id, "top-right")

engine.split(top_left, Direction::Vertical, "kitty", "shell")
engine.split(top_right, Direction::Vertical, "btop", "monitor")

mail = engine.register("thunderbird", "mail")
engine.move(mail.id, "top-right")

Example.title("A two by two grid, with a stacked pane top right")
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("Neighbours of every visible window")
engine.visible_windows.each do |window|
  edges = Edge.values.map do |edge|
    target = engine.neighbor(window.id, edge)
    "#{edge.to_s.downcase.ljust(5)}:#{(target.try(&.title) || "-").ljust(8)}"
  end
  Example.line("#{window.title.ljust(9)} #{edges.join(" ")}")
end

Example.step("Walking the grid")
Example.status("focus editor", engine.focus(editor.id))
{Edge::Right, Edge::Down, Edge::Left, Edge::Up}.each do |edge|
  Example.status("focus #{edge.to_s.downcase}", engine.focus_edge(edge))
  Example.line("focused: #{engine.focused_window.try(&.title)}")
end

Example.step("Cycling focus in tree order")
engine.focus_order.size.times do
  Example.status("focus_next", engine.focus_next)
  Example.line("focused: #{engine.focused_window.try(&.title)}")
end

Example.step("Cycling inside one stack")
Example.status("focus browser", engine.focus(browser.id))
Example.status("focus_stack_next", engine.focus_stack_next)
engine.apply
Example.canvas(engine)
Example.legend(engine)
