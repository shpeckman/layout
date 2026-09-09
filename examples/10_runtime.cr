# examples/10_runtime.cr
require "./support"

engine  = Engine.new(Screen.new(80, 18), default_stack: "main")
runtime = Runtime.new(engine)
frames  = [] of Array(Change)
done    = Channel(Nil).new

Example.title("Driving the engine from an isolated execution context")
runtime.start
Example.line("phase=#{runtime.phase} running?=#{runtime.running?}")

spawn do
  while frame = runtime.frames.receive?
    frames << frame
  end
  done.send(nil)
end

runtime.submit { |session| session.register("waybar", "panel") }
runtime.submit { |session| session.register("nvim", "editor") }
runtime.submit do |session|
  shell = session.register("kitty", "shell")
  session.move(shell.id, "side", activate: true)
end
runtime.resize(100, 22)
runtime.refresh

runtime.stop
done.receive

Example.step("Frames received")
Example.line("#{frames.size} frame(s); queued intents are coalesced into one pass")
frames.each_with_index do |frame, index|
  Example.step("frame #{index + 1}")
  Example.changes(frame)
end

Example.step("Final state of the shared engine")
Example.windows(engine)
Example.canvas(engine)
Example.legend(engine)

Example.step("After stop the channel is closed")
Example.line("phase=#{runtime.phase} closed?=#{runtime.closed?}")
Example.line("submit -> #{runtime.submit(&.dirty!)}")
