# examples/08_scratchpads.cr
require "./support"

engine = Engine.new(Screen.new(70, 18), default_stack: "main")

engine.add_rule(Rule.new(
  Match.build(app_id: "kitty", tag: "drop"),
  Action.new(scratchpad: "term", stop: true)
))

engine.register("nvim", "editor")
browser = engine.register("firefox", "browser")
engine.move(browser.id, "side")

term = engine.register("kitty", "dropdown", "drop")
pad  = engine.bind_scratchpad("term", term.id, width: 50, height: 6)

notes = engine.register("obsidian", "notes")
notes.layer = Layer::Floating
engine.update(notes)
engine.bind_scratchpad("notes", notes.id, width: 22, height: 9)

Example.title("Scratchpads start hidden and off the tiling tree")
engine.apply
Example.windows(engine)
Example.canvas(engine)
Example.line("bound pads: #{engine.scratchpads.keys.join(", ")}")

Example.step("Toggle the terminal in")
Example.status("toggle_scratchpad term", engine.toggle_scratchpad("term"))
engine.apply
Example.canvas(engine)
Example.line("shown? #{pad.shown?} focused: #{engine.focused_window.try(&.title)}")

Example.step("Both pads open at once")
Example.status("toggle_scratchpad notes", engine.toggle_scratchpad("notes"))
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("Toggle them back out")
Example.status("toggle_scratchpad term", engine.toggle_scratchpad("term"))
Example.status("toggle_scratchpad notes", engine.toggle_scratchpad("notes"))
engine.apply
Example.windows(engine)
Example.canvas(engine)

Example.step("An unbound name is simply missing")
Example.status("toggle_scratchpad music", engine.toggle_scratchpad("music"))
