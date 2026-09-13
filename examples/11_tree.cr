# examples/11_tree.cr
require "./support"

engine = Engine.new(Screen.new(80, 20), default_stack: "main")

main = engine.create_stack("main")
editor = engine.register("nvim", "editor")
browser = engine.register("firefox", "browser")

side = engine.create_stack("side", near: main, direction: Direction::Horizontal)
engine.move(engine.register("kitty", "shell").id, "side")

monitor_stack = engine.split(side, Direction::Vertical, "btop", "monitor")
logs_stack = engine.split(monitor_stack, Direction::Horizontal, "tail", "logs")

Example.title("Initial layout tree")
engine.apply
Example.tree(engine)
Example.canvas(engine)

Example.step("Change focus in the main stack")
Example.status("focus editor", engine.focus(editor.id))
engine.apply
Example.tree(engine)

Example.step("Promote the logs stack up the tree")
Example.status("promote_node", engine.promote_node(logs_stack))
engine.apply
Example.tree(engine)
Example.canvas(engine)