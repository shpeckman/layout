# examples/09_changes.cr
require "./support"

engine = Engine.new(Screen.new(60, 14), default_stack: "main")

editor = engine.register("nvim", "editor")
Example.title("The first pass makes everything appear")
Example.changes(engine.apply)

shell = engine.register("kitty", "shell")
engine.move(shell.id, "side")
Example.step("A second stack halves the screen")
Example.changes(engine.apply)
Example.canvas(engine)

Example.step("Nothing is dirty, so nothing is recomputed")
Example.changes(engine.apply)
Example.line("dirty? #{engine.dirty?}")

Example.step("A forced pass recomputes but still diffs to nothing")
Example.changes(engine.apply(force: true))

Example.step("Resizing the screen moves both windows")
Example.status("resize_screen", engine.resize_screen(90, 20))
Example.changes(engine.apply)
Example.canvas(engine)

Example.step("Fullscreen hides the peer")
Example.status("toggle_fullscreen", engine.toggle_fullscreen(editor.id))
Example.changes(engine.apply)
Example.canvas(engine)

Example.step("Leaving fullscreen brings it back")
Example.status("toggle_fullscreen", engine.toggle_fullscreen(editor.id))
Example.changes(engine.apply)

Example.step("Closing a window frees its space")
engine.unregister(shell.id)
Example.changes(engine.apply)
Example.canvas(engine)
Example.line("engine.changes still holds #{engine.changes.size} entr(y|ies)")
