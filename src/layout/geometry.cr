# src/layout/geometry.cr
module Layout
  struct Rect
    getter x    : Int32
    getter y    : Int32
    getter cols : Int32
    getter rows : Int32

    def initialize(@x : Int32 = 0, @y : Int32 = 0, @cols : Int32 = 0, @rows : Int32 = 0)
    end

    def right : Int32
      x + cols
    end

    def bottom : Int32
      y + rows
    end

    def center_x : Int32
      x + cols // 2
    end

    def center_y : Int32
      y + rows // 2
    end

    def empty? : Bool
      cols <= 0 || rows <= 0
    end

    def contains?(px : Int32, py : Int32) : Bool
      px >= x && py >= y && px < right && py < bottom
    end

    def contains?(other : Rect) : Bool
      other.x >= x && other.y >= y && other.right <= right && other.bottom <= bottom
    end

    def intersects?(other : Rect) : Bool
      x < other.right && other.x < right && y < other.bottom && other.y < bottom
    end

    def translate(dx : Int32, dy : Int32) : Rect
      Rect.new(x + dx, y + dy, cols, rows)
    end

    def inset(amount : Int32) : Rect
      inset(amount, amount, amount, amount)
    end

    def inset(left : Int32, top : Int32, right : Int32, bottom : Int32) : Rect
      width  = cols - left - right
      height = rows - top - bottom
      Rect.new(x + left, y + top, width > 0 ? width : 0, height > 0 ? height : 0)
    end

    def span(direction : Direction) : Int32
      direction.horizontal? ? cols : rows
    end

    def offset(direction : Direction) : Int32
      direction.horizontal? ? x : y
    end

    def slice(direction : Direction, offset : Int32, span : Int32) : Rect
      if direction.horizontal?
        Rect.new(offset, y, span, rows)
      else
        Rect.new(x, offset, cols, span)
      end
    end

    def centered(width : Int32, height : Int32) : Rect
      w = width > cols ? cols : width
      h = height > rows ? rows : height
      Rect.new(x + (cols - w) // 2, y + (rows - h) // 2, w, h)
    end

    def band(side : Side, size : Int32) : Rect
      thickness = size
      case side
      in Side::Top
        thickness = rows if thickness > rows
        Rect.new(x, y, cols, thickness)
      in Side::Bottom
        thickness = rows if thickness > rows
        Rect.new(x, bottom - thickness, cols, thickness)
      in Side::Left
        thickness = cols if thickness > cols
        Rect.new(x, y, thickness, rows)
      in Side::Right
        thickness = cols if thickness > cols
        Rect.new(right - thickness, y, thickness, rows)
      end
    end
  end

  struct CellSize
    getter width  : Int32
    getter height : Int32

    def initialize(@width : Int32 = 1, @height : Int32 = 1)
    end
  end

  struct PixelRect
    getter x      : Int32
    getter y      : Int32
    getter width  : Int32
    getter height : Int32

    def initialize(@x : Int32 = 0, @y : Int32 = 0, @width : Int32 = 0, @height : Int32 = 0)
    end
  end

  struct Sizing
    getter weight : Int32
    getter fixed  : Int32?
    getter min    : Int32?
    getter max    : Int32?

    def initialize(@weight : Int32 = 1, @fixed : Int32? = nil,
                   @min : Int32? = nil, @max : Int32? = nil)
    end

    def fixed? : Bool
      !fixed.nil?
    end

    def with_weight(value : Int32) : Sizing
      Sizing.new(value, fixed, min, max)
    end

    def with_fixed(value : Int32?) : Sizing
      Sizing.new(weight, value, min, max)
    end

    def with_min(value : Int32?) : Sizing
      Sizing.new(weight, fixed, value, max)
    end

    def with_max(value : Int32?) : Sizing
      Sizing.new(weight, fixed, min, value)
    end

    def clamp_span(span : Int32) : Int32
      result = span
      if low = min
        result = low if result < low
      end
      if high = max
        result = high if result > high
      end
      result
    end
  end

  struct Strut
    getter side : Side
    getter size : Int32

    def initialize(@side : Side, @size : Int32 = 0)
    end

    def active? : Bool
      size > 0
    end
  end
end
