# examples/02_stacks_and_splits.cr
require "./support"

engine = Engine.new(Screen.new(90, 20), default_stack: "code")

code = engine.create_stack("code")
engine.register("nvim", "layout.cr")

docs      = engine.create_stack("docs", near: code, direction: Direction::Horizontal)
reference = engine.register("zathura", "crystal-book.pdf")
Example.status("move reference", engine.move(reference.id, "docs"))

logs = engine.split(code, Direction::Vertical, "kitty", "build.log")

Example.title("A split tree of three panes")
engine.apply
Example.windows(engine)
Example.canvas(engine)
Example.legend(engine)

Example.step("Flip the orientation of the root split")
if root = engine.current.tiled.root
  Example.status("toggle_direction", engine.toggle_direction(root))
end
engine.apply
Example.canvas(engine)

Example.step("Promote the log pane one level up")
Example.status("promote_node", engine.promote_node(logs))
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("Swap two sibling stacks")
Example.status("swap_nodes", engine.swap_nodes(code, docs))
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("Look the tree up again")
Example.line("stack('docs') -> ##{engine.stack("docs").try(&.id)}")
if root = engine.current.tiled.root
  Example.line("root ##{root.id} #{root.class} children=#{root.size}")
  Example.line("node(#{root.id}) -> ##{engine.node(root.id).try(&.id)}")
end
