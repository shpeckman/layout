# examples/07_floating_and_modals.cr
require "./support"

engine = Engine.new(Screen.new(70, 18), default_stack: "main")

engine.add_rule(Rule.new(Match.app_id("gtk-dialog"), Action.new(layer: Layer::Floating, focus: true)))
engine.add_rule(Rule.new(Match.app_id("mpv"), Action.new(layer: Layer::Floating)))
engine.add_rule(Rule.new(Match.app_id("rofi"), Action.new(layer: Layer::Overlay, focus: true, stop: true)))

editor = engine.register("nvim", "editor")
files  = engine.register("thunar", "files")
engine.move(files.id, "side")

Example.title("Tiled base layer")
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("A modal centres itself on its parent")
dialog = engine.register("gtk-dialog", "save?", parent: files.id)
dialog.rect = Rect.new(0, 0, 22, 5)
engine.apply
Example.canvas(engine)
Example.line("modal? #{dialog.modal?} parent=##{dialog.parent}")

Example.step("A floating video and an overlay launcher")
video = engine.register("mpv", "video")
video.rect = Rect.new(0, 0, 30, 7)
launcher = engine.register("rofi", "launcher")
launcher.rect = Rect.new(0, 0, 40, 4)
engine.apply
Example.canvas(engine)
Example.legend(engine)
Example.line("render order: #{engine.render_order.map(&.title).join(" < ")}")

Example.step("Z-order inside the floating layer")
Example.status("lower video", engine.lower(video.id))
Example.line("render order: #{engine.render_order.map(&.title).join(" < ")}")
Example.status("raise_to_top video", engine.raise_to_top(video.id))
Example.line("render order: #{engine.render_order.map(&.title).join(" < ")}")
engine.apply
Example.canvas(engine)

Example.step("Hit testing picks the topmost visible window")
{ {4, 4}, {35, 9}, {60, 14} }.each do |(x, y)|
  Example.line("(#{x},#{y}) -> #{engine.window_at(x, y).try(&.title) || "nothing"}")
end

Example.step("Maximize the video, then fullscreen the editor")
Example.status("toggle_maximize", engine.toggle_maximize(video.id))
engine.apply
Example.canvas(engine)
Example.status("toggle_fullscreen", engine.toggle_fullscreen(editor.id))
engine.apply
Example.canvas(engine)
Example.line("workspace fullscreen: ##{engine.fullscreen}")
Example.status("toggle_fullscreen", engine.toggle_fullscreen(editor.id))
engine.apply

Example.step("Closing a parent takes its modals with it")
Example.line("before: #{engine.windows.size} windows")
engine.unregister(files.id)
engine.apply
Example.line("after:  #{engine.windows.size} windows")
Example.windows(engine)
Example.canvas(engine)
