class Cls < Prawn::Document
  def initialize(sight_data = {})
    @sight_data = sight_data
    super()
  end

  def draw
    Cls.generate('test.pdf') do
      stroke_axis
      frame
      mid_lat(@sight_data[:latitude])
    end
  end

  def save_to_file(path)
    File.open(path, 'w+') { |f| f.write(render) }
  end

  private

  def frame
    self.line_width = 0.5
    stroke_color '009900'

    vertical_line 0, 648, at: 275
    horizontal_line 20, 520, at: 162
    horizontal_line 20, 520, at: 405

    hash_marks

    bounding_box([20, 648], width: 500, height: 648) do
      stroke_bounds
    end
  end

  def hash_marks
    (1..80).each do |n|
      if (n % 10).zero?
        left = 30
        right = 510
      elsif (n % 5).zero?
        left = 25
        right = 515
      else
        left = 23
        right = 517
      end
      horizontal_line 20, left, at: (n * 81 / 10)
      horizontal_line right, 520, at: (n * 81 / 10)
    end
  end

  def mid_lat(latitude)
    #
  end
end
