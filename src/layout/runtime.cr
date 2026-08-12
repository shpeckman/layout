# src/layout/runtime.cr
class Layout::Runtime
  alias Intent = Engine ->

  CONTEXT_NAME = "terminal:layout"
  INTENT_CAP   = 256
  FRAME_CAP    =  64

  enum Phase
    Idle
    Running
    Closed
  end

  getter frames : Channel(Array(Change))

  @engine  : Engine
  @intents : Channel(Intent)
  @phase   : Atomic(Phase)
  @context : Fiber::ExecutionContext::Isolated?

  def initialize(@engine : Engine = Engine.new,
                 intent_cap : Int32 = INTENT_CAP, frame_cap : Int32 = FRAME_CAP)
    @intents = Channel(Intent).new(intent_cap)
    @frames  = Channel(Array(Change)).new(frame_cap)
    @phase   = Atomic(Phase).new(Phase::Idle)
    @context = nil
  end

  def phase : Phase
    @phase.get
  end

  def running? : Bool
    @phase.get.running?
  end

  def closed? : Bool
    @phase.get.closed?
  end

  def start : Nil
    return unless @phase.compare_and_set(Phase::Idle, Phase::Running)[1]
    @context = Fiber::ExecutionContext::Isolated.new(CONTEXT_NAME) { run }
  end

  def stop : Nil
    return if @phase.get.closed?
    @intents.close
    wait
    @phase.set(Phase::Closed)
  end

  def wait : Nil
    @context.try(&.wait)
  end

  def submit(intent : Intent) : Bool
    @intents.send(intent)
    true
  rescue Channel::ClosedError
    false
  end

  def submit(&intent : Intent) : Bool
    submit(intent)
  end

  def resize(cols : Int32, rows : Int32) : Bool
    submit do |engine|
      engine.resize_screen(cols, rows)
    end
  end

  def refresh : Bool
    submit(&.dirty!)
  end

  private def run : Nil
    loop do
      intent = @intents.receive?
      break if intent.nil?

      intent.call(@engine)
      break unless drain
      emit
    end
  ensure
    @phase.set(Phase::Closed)
    @frames.close
  end

  private def drain : Bool
    loop do
      select
      when intent = @intents.receive?
        return false if intent.nil?
        intent.call(@engine)
      else
        return true
      end
    end
  end

  private def emit : Nil
    changes = @engine.apply
    return if changes.empty?
    @frames.send(changes.dup)
  rescue Channel::ClosedError
  end
end

