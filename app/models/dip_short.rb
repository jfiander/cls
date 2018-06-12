class DipShort < Prawn::Document
  def self.guide(radius = 60, rings = 5, offset = 0)
    # radius 65.625 matches chart 14850 (1:60000 scale)
    DipShort.generate('tmp/DS.pdf') do
      rings(radius, rings, offset)
    end

    'tmp/DS.pdf'
  end

  def self.compass(radius = 60)
    DipShort.generate('tmp/Compass.pdf') do
      rings(radius, 4, outer_ring_only: true)
    end

    'tmp/Compass.pdf'
  end

  private

  def rings(base_radius = 20, max_nm = 5, offset = 0, origin: [270, 360], outer_ring_only: false)
    origin = [origin[0] - offset, origin[1]] unless offset.zero?
    base_radius = base_radius.to_d
    max_step = (10 * (max_nm - 1))
    stroke_color 'FF00FF'
    increment = base_radius / 10

    self.line_width = 0.5
    [30, 60].each do |r|
      rotate(r, origin: [origin[0], origin[1]]) do
        self.line_width = 0.25
        dash([2, 2])
        stroke { line [((origin[0] - base_radius) - (max_step * increment)), origin[1]], [((origin[0] + base_radius) + (max_step * increment)), origin[1]] }
        stroke { line [origin[0], (origin[1] - base_radius) - (max_step * increment)], [origin[0], (origin[1] + base_radius) + (max_step * increment)] }
        undash
      end
    end
    self.line_width = 0.5
    horizontal_line ((origin[0] - base_radius) - (max_step * increment)), ((origin[0] + base_radius) + (max_step * increment)), at: origin[1]
    vertical_line ((origin[1] - base_radius) - (max_step * increment)), ((origin[1] + base_radius) + (max_step * increment)), at: origin[0]

    if outer_ring_only
      self.line_width = 0.5
      radius = base_radius + (increment * max_step)
      stroke_circle([origin[0], origin[1]], radius)
    else
      (0..max_step).each do |step|
        radius = base_radius + (increment * step)
        if (step % 10).zero?
          undash
          self.line_width = 0.5
        else
          dash([3, 2])
          self.line_width = 0.1
        end
        stroke_circle([origin[0], origin[1]], radius)
      end
    end

    (1..360).each do |n|
      rotate(n, origin: [270, 360]) do
        self.line_width = 0.1
        stroke do
          line(
            [270, (360 + radius)],
            [270, (360 + radius - ((n % 10).zero? ? 15 : 5))]
          )
        end
      end
    end
  end
end
