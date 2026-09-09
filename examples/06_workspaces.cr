# examples/06_workspaces.cr
require "./support"

engine = Engine.new(Screen.new(70, 16), default_stack: "main", workspaces: 2)

Example.title("Workspaces are independent trees over one screen")
Example.line("count=#{engine.workspaces.size} active=#{engine.active}")

engine.register("nvim", "editor")
shell = engine.register("kitty", "shell")
engine.move(shell.id, "side")
engine.apply
Example.canvas(engine)
Example.legend(engine)

comms = engine.add_workspace("comms")
index = engine.workspaces.size - 1

Example.step("Send the shell to '#{comms.name}' (workspace #{index})")
Example.status("move_to_workspace", engine.move_to_workspace(shell.id, index, activate: true))
engine.apply
Example.windows(engine)
Example.canvas(engine)

Example.step("Switch to that workspace")
Example.status("switch_workspace", engine.switch_workspace(index))
engine.apply
Example.canvas(engine)
Example.line("focused: #{engine.focused_window.try(&.title)}")

Example.step("A sticky floating window follows every workspace")
notes = engine.register("obsidian", "notes")
notes.layer = Layer::Floating
notes.rect = Rect.new(0, 0, 24, 5)
Example.status("update", engine.update(notes))
Example.status("set_sticky", engine.set_sticky(notes.id, true))
engine.apply
Example.canvas(engine)
Example.legend(engine)

Example.step("switch_prev wraps around the list")
engine.workspaces.size.times do
  Example.status("switch_prev", engine.switch_prev)
  engine.apply
  Example.line("active=#{engine.active} name=#{engine.current.name || "-"}")
  Example.canvas(engine)
end
