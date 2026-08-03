# src/layout/enums.cr
module Layout
  enum Status
    Changed
    Unchanged
    Missing
    Rejected

    def success? : Bool
      changed? || unchanged?
    end
  end

  enum Direction
    Horizontal
    Vertical
  end

  enum Edge
    Left
    Right
    Up
    Down

    def direction : Direction
      left? || right? ? Direction::Horizontal : Direction::Vertical
    end

    def forward? : Bool
      right? || down?
    end
  end

  enum Side
    Top
    Bottom
    Left
    Right

    def direction : Direction
      left? || right? ? Direction::Horizontal : Direction::Vertical
    end
  end

  enum Layer
    Background = 0
    Tiled      = 1
    Floating   = 2
    Overlay    = 3
  end

  enum Mode
    Normal
    Maximized
    Fullscreen

    def override? : Bool
      maximized? || fullscreen?
    end
  end

  @[Flags]
  enum Field
    Layer
    Stack
    Weight
    Fixed
    Min
    Max
    Focus
    Strut
    Scratchpad
    Sticky
    Workspace
  end
end
