# examples/01_basic_tiling.cr
require "./support"

engine = Engine.new(Screen.new(80, 18))

editor  = engine.register("nvim", "src/layout.cr")
browser = engine.register("firefox", "crystal-lang.org")
shell   = engine.register("kitty", "shell")

Example.title("Every window lands in the default stack")
engine.apply
Example.windows(engine)
Example.canvas(engine)
Example.line("a stack shows only its active window")

Example.step("Move two of them into a second stack")
Example.status("move browser", engine.move(browser.id, "side"))
Example.status("move shell", engine.move(shell.id, "side", activate: true))
engine.apply
Example.windows(engine)
Example.canvas(engine)
Example.legend(engine)

Example.step("Cycle the active window of the side stack")
Example.status("focus stack next", engine.focus_stack_next)
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("Focus travels back to the editor")
Example.status("focus editor", engine.focus(editor.id))
Example.line("focused: #{engine.focused_window.try(&.title)}")
