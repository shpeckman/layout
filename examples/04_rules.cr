# examples/04_rules.cr
require "./support"

def report(engine : Engine, window : Window) : Nil
  resolution = engine.last_resolution
  return unless resolution
  Example.line(
    "#{window.app_id.ljust(13)} rules=#{resolution.matched.inspect.ljust(11)} " \
    "stack=#{(resolution.target || "-").ljust(8)} focus=#{resolution.focus?} " \
    "layer=#{window.layer} weight=#{window.sizing.weight}"
  )
end

engine = Engine.new(Screen.new(90, 20), default_stack: "code")

engine.add_rule(Rule.new(
  Match.app_id("waybar"),
  Action.new(layer: Layer::Overlay, strut: Strut.new(Side::Top, 2), stop: true),
  priority: -100
))
engine.add_rule(Rule.new(
  Match.any(Match.app_id("pavucontrol"), Match.title(/^Picture-in-Picture$/)),
  Action.new(layer: Layer::Floating, focus: true, stop: true),
  priority: -50
))
engine.add_rule(Rule.new(
  Match.not(Match.any(Match.app_id("nvim"), Match.app_id("waybar"))),
  Action.new(stack: "side"),
  priority: -5
))
engine.add_rule(Rule.new(
  Match.tag("dev"),
  Action.new(stack: "code", weight: 3, focus: true)
))
engine.add_rule(Rule.new(
  Match.app_id("nvim"),
  Action.new(stack: "editor", clear: Field::Weight | Field::Focus),
  priority: 10
))

requests = [
  {"waybar",      "panel",              nil},
  {"nvim",        "layout.cr",          "dev"},
  {"kitty",       "shell",              "dev"},
  {"pavucontrol", "Volume",             nil},
  {"firefox",     "Picture-in-Picture", nil},
  {"thunar",      "files",              nil},
] of Tuple(String, String, String?)

Example.title("Rules resolve placement at registration time")
Example.line("rules run low priority first, so the last one to run wins")
requests.each do |(app_id, title, tag)|
  report(engine, engine.register(app_id, title, tag))
end

engine.apply
Example.step("Resulting layout")
Example.windows(engine)
Example.canvas(engine)
Example.legend(engine)
Example.line("the panel reserves two rows through its strut")

Example.step("Retagging replays the whole chain")
target = engine.windows.find { |window| window.app_id == "thunar" }
if target
  Example.status("retag dev", engine.retag(target.id, "dev"))
  report(engine, target)
  engine.apply
  Example.canvas(engine)
  Example.legend(engine)
end

Example.step("Bulk moves by tag")
Example.line("moved #{engine.move_by_tag("dev", "code")} window(s) into 'code'")
engine.apply
Example.canvas(engine)
Example.legend(engine)
