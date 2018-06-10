class Cls < Prawn::Document
  def initialize(sight_data = {})
    super()
    $sight_data = sight_data
  end

  def draw
    Cls.generate('tmp/CLS.pdf') do
      frame
      mid_lat($sight_data[:latitude])
      label_increments($sight_data[:increment], $sight_data[:longitude])
    end

    'tmp/CLS.pdf'
  end

  def save_to_file(path)
    File.open(path, 'w+') { |f| f.write(render) }
  end

  private

  def frame
    self.line_width = 0.25
    stroke_color '009900'
    fill_color '009900'

    longitude_arcs

    # Mask some unneeded lines
    fill_color 'FFFFFF'
    max_mid_lat_height = 250 * Math.tan(55 * Math::PI / 180)
    fill_polygon([270, 0], [20, max_mid_lat_height], [520, max_mid_lat_height], [270, 0])
    fill_polygon([0, -1], [0, -100], [540, -100], [540, -1])
    fill_color '009900'

    vertical_line 0, 648, at: 270
    horizontal_line 20, 520, at: 162
    horizontal_line 20, 520, at: 405

    rectangle([20, 648], 500, 648)

    hash_marks

    compass
  end

  def longitude_arcs
    (1..30).each do |n|
      radius = n * 250.to_f / 30

      dash([5, 2]) unless (n % 10).zero?
      self.line_width = 0.75 if (n % 5).zero?
      stroke_circle [270, 0], radius
      self.line_width = 0.25 if (n % 5).zero?
      undash
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

  def compass
    stroke_circle [270, 405], 225

    (0..359).each do |n|
      next if (n % 90).zero?
      rotate((n * -1), origin: [270, 405]) do
        draw_text '|', size: ((n % 10).zero? ? 10 : 7), at: [((n % 10).zero? ? 268.75 : 269), ((n % 10).zero? ? 622.5 : 625)]
      end
    end

    (0..35).each do |n|
      rotate((n * -10), origin: [270, 405]) do
        draw_text n * 10, size: 7, at: [268, 632]
      end
    end
  end

  def mid_lat(latitude)
    lat_radians = latitude.to_d * Math::PI / 180
    mid_lat_height = 250 * Math.tan(lat_radians)
    big_long_line = 250 * Math.cos(lat_radians)
    mid_long_line_x = 250.to_f * 2 / 3 * Math.cos(lat_radians)
    close_long_line_x = 250.to_f / 3 * Math.cos(lat_radians)
    mid_long_line_y = 250.to_f * 2 / 3 * Math.sin(lat_radians)
    close_long_line_y = 250.to_f / 3 * Math.sin(lat_radians)

    stroke do
      stroke_color '000099'
      self.line_width = 0.5
      line [270, 0], [20, mid_lat_height]
      line [270, 0], [520, mid_lat_height]

      vertical_line 0, 648, at: 270 - big_long_line
      vertical_line 0, 648, at: 270 + big_long_line

      vertical_line 0, mid_long_line_y, at: 270 - mid_long_line_x
      vertical_line 0, mid_long_line_y, at: 270 + mid_long_line_x

      vertical_line 0, close_long_line_y, at: 270 - close_long_line_x
      vertical_line 0, close_long_line_y, at: 270 + close_long_line_x
    end

    fill_color '000099'
    draw_text latitude, size: 10, at: [530, 402]
  end

  def label_increments(increment, longitude)
    #
  end
end
