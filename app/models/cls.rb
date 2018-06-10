class Cls < Prawn::Document
  def initialize(sight_data = {})
    @sight_data = sight_data
    super()
  end

  def draw
    Cls.generate('test.pdf') do
      # stroke_axis
      frame
      mid_lat(@sight_data[:latitude])
    end
  end

  def save_to_file(path)
    File.open(path, 'w+') { |f| f.write(render) }
  end

  private

  def frame
    self.line_width = 0.25
    stroke_color '009900'

    rectangle([20, 648], 500, 648)

    vertical_line 0, 648, at: 275
    horizontal_line 20, 520, at: 162
    horizontal_line 20, 520, at: 405

    fill_color '009900'

    hash_marks

    compass
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

  def compass
    stroke_circle [275, 405], 225

    (0..359).each do |n|
      next if (n % 90).zero?
      rotate((n * -1), origin: [275, 405]) do
        vertical_line 615, 625, at: 275
        draw_text '|', size: ((n % 10).zero? ? 10 : 7), at: [274, ((n % 10).zero? ? 622.5 : 625)]
      end
    end

    fill_color '009900'
    (0..35).each do |n|
      rotate((n * -10), origin: [275, 405]) do
        draw_text n * 10, size: 7, at: [273, 632]
      end
    end
  end

  def mid_lat(latitude)
    #
  end
end
