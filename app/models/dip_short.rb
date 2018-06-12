class DipShort < Prawn::Document
  # def initialize
  #   super()
  # end

  def self.guide(radius = 60, rings = 5)
    DipShort.generate('tmp/DS.pdf') do
      rings(radius, rings)
    end

    'tmp/DS.pdf'
  end

  private

  def rings(base_radius = 20, max_nm = 5, origin: [270, 405])
    base_radius = base_radius.to_d
    max_step = (10 * (max_nm - 1))
    stroke_color 'FF00FF'
    increment = base_radius / 10

    self.line_width = 0.5
    rotate(45, origin: [origin[0], origin[1]]) do
      self.line_width = 0.25
      dash([2, 2])
      stroke { line [((origin[0] - base_radius) - (max_step * increment)), origin[1]], [((origin[0] + base_radius) + (max_step * increment)), origin[1]] }
      stroke { line [origin[0], (origin[1] - base_radius) - (max_step * increment)], [origin[0], (origin[1] + base_radius) + (max_step * increment)] }
      undash
    end
    self.line_width = 0.5
    horizontal_line ((origin[0] - base_radius) - (max_step * increment)), ((origin[0] + base_radius) + (max_step * increment)), at: origin[1]
    vertical_line ((origin[1] - base_radius) - (max_step * increment)), ((origin[1] + base_radius) + (max_step * increment)), at: origin[0]

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
end
