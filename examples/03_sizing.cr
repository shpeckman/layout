# examples/03_sizing.cr
require "./support"

NAMES = ["main", "side", "tools"]

def spans(engine : Engine) : Nil
  NAMES.each do |name|
    stack = engine.stack(name)
    next unless stack
    sizing = stack.sizing
    Example.line(
      "#{name.ljust(6)} #{Example.area(stack.rect)}  weight=#{sizing.weight} " \
      "fixed=#{sizing.fixed || "-"} min=#{sizing.min || "-"} max=#{sizing.max || "-"}"
    )
  end
end

engine = Engine.new(Screen.new(100, 16), default_stack: "main")

main   = engine.create_stack("main")
editor = engine.register("nvim", "editor")
side   = engine.create_stack("side", near: main, direction: Direction::Horizontal)
engine.move(engine.register("kitty", "shell").id, "side")
tools = engine.create_stack("tools", near: side, direction: Direction::Horizontal)
engine.move(engine.register("btop", "monitor").id, "tools")

Example.title("Equal weights, equal shares")
engine.apply
spans(engine)
Example.canvas(engine)

Example.step("Weight the editor three to one")
Example.status("set_weight main 3", engine.set_weight(main, 3))
engine.apply
spans(engine)
Example.canvas(engine)

Example.step("A maximum reclaims the surplus for the siblings")
Example.status("set_max main 40", engine.set_max(main, 40))
engine.apply
spans(engine)
Example.canvas(engine)

Example.step("A minimum pushes a sibling down")
Example.status("set_min side 45", engine.set_min(side, 45))
engine.apply
spans(engine)

Example.step("A fixed span opts out of weighting entirely")
Example.status("set_fixed tools 12", engine.set_fixed(tools, 12))
engine.apply
spans(engine)
Example.canvas(engine)

Example.step("Clear the constraints again")
Example.status("set_max main nil", engine.set_max(main, nil))
Example.status("set_min side nil", engine.set_min(side, nil))
engine.apply
spans(engine)

Example.step("Drag the boundary between the editor and its peer")
Example.status("resize_window -25", engine.resize_window(editor.id, -25))
engine.apply
spans(engine)
Example.canvas(engine)
