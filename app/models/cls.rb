class Cls < Prawn::Document
  def initialize(sight_data = {})
    super()
    $sight_data = sight_data
  end

  def draw(plots)
    Cls.generate('tmp/CLS.pdf') do
      frame

      set_colors '000000'
      plots.each { |plot| send("draw_#{plot.keys.first}", *plot.values.first) }
      set_colors '000099'

      top_info($sight_data[:name], $sight_data[:squadron], $sight_data[:sight_number])
      mid_lat($sight_data[:latitude])
      label_increments($sight_data[:increment], $sight_data[:latitude], $sight_data[:longitude])

      # Could be expanded to calculate three-body fixes
      plot_intersection($lines.first(2)) if $lines.count == 2
      $lines = []
    end

    'tmp/CLS.pdf'
  end

  def save_to_file(path)
    File.open(path, 'w+') { |f| f.write(render) }
  end

  def draw_point(lat, lon)
    point(coordinates(lat, lon))
  end

  def draw_circle(lat, lon)
    plot_circle(coordinates(lat, lon))
  end

  def draw_fix(lat, lon, label = '', offset = 10)
    point(coordinates(lat, lon))
    plot_circle(coordinates(lat, lon))
    return unless label.present?

    x, y = coordinates(lat, lon)
    if label[0].match?(/d/)
      do_rotate = true
      label = label[1..label.length]
    end
    rotate((do_rotate ? 45 : 0), origin: [x, y]) do
      draw_text label, size: 8, at: [x + offset, y]
    end
  end

  def draw_track(angle, lat, lon)
    track(angle, coordinates(lat, lon))
  end

  def draw_intercept(angle, dist, lat, lon)
    int = intercept(angle, dist, origin: coordinates(lat, lon))
    s_err = lop(int, plot_ep: $sight_data[:plot_ep])[1].abs

    draw_text("S Err   #{(s_err / 8.1).to_f} nm", size: 10, at: [245, 125]) if $sight_data[:sight_error].present?
  end

  def draw_position(label, lat, lon)
    draw_text("#{label}   #{display_degrees(lat, axis: :ns, force_degree: true, decimal: true)}", size: 10, at: [255, 125])
    draw_text("#{display_degrees(lon, axis: :ew, force_degree: true, decimal: true)}", size: 10, at: [276, 110])
  end

  private

  def set_colors(color)
    fill_color color
    stroke_color color
  end

  def frame
    self.line_width = 0.25
    set_colors '009900'

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
      next if n.in?([20, 50, 80])
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
    set_colors '000099'
    self.line_width = 0.75

    stroke do
      line [270, 0], [20, long_meridians(latitude)[:mid_lat_height]]
      line [270, 0], [520, long_meridians(latitude)[:mid_lat_height]]

      vertical_line 0, 648, at: 270 - long_meridians(latitude)[:big_long_line]
      vertical_line 0, 648, at: 270 + long_meridians(latitude)[:big_long_line]

      vertical_line 0, long_meridians(latitude)[:mid_long_line_y], at: 270 - long_meridians(latitude)[:mid_long_line_x]
      vertical_line 0, long_meridians(latitude)[:mid_long_line_y], at: 270 + long_meridians(latitude)[:mid_long_line_x]

      vertical_line 0, long_meridians(latitude)[:close_long_line_y], at: 270 - long_meridians(latitude)[:close_long_line_x]
      vertical_line 0, long_meridians(latitude)[:close_long_line_y], at: 270 + long_meridians(latitude)[:close_long_line_x]
    end

    draw_text display_degrees(latitude, axis: :ns, force_degree: true), size: 10, at: [530, 402]
  end

  def long_meridians(latitude)
    lat_radians = latitude.to_d * Math::PI / 180

    {
      mid_lat_height: 250 * Math.tan(lat_radians),
      big_long_line: 250 * Math.cos(lat_radians),
      mid_long_line_x: 250.to_f * 2 / 3 * Math.cos(lat_radians),
      close_long_line_x: 250.to_f / 3 * Math.cos(lat_radians),
      mid_long_line_y: 250.to_f * 2 / 3 * Math.sin(lat_radians),
      close_long_line_y: 250.to_f / 3 * Math.sin(lat_radians)
    }
  end

  def label_increments(increment, latitude, longitude)
    # Mid-Longitude
    draw_text display_degrees(longitude, axis: :ew, force_degree: true), size: 10, at: [250, -20]

    (-3..3).each do |i|
      next if i.zero?

      inc = i * increment.to_i

      lat = display_degrees(increment_degrees(latitude, inc), axis: :ns, force_degree: true)
      lon = display_degrees(increment_degrees(longitude, inc), axis: :ew, force_degree: true)

      draw_text display_degrees(lat, axis: :ns), size: 10, at: [530, 402 + 81 * i]
      draw_text display_degrees(lon, axis: :ew), size: 10, at: [260 + long_meridians(latitude)[:close_long_line_x] * i * -1, -20]
    end
  end

  def display_degrees(degrees, axis:, decimal: false, force_degree: false)
    d, m, negative = parse_degrees(degrees)

    m = decimal ? m.round(1) : m.round
    symbol = axis_symbol(negative, axis)

    if force_degree
      m.zero? ? "#{d}° #{symbol}" : "#{d}° #{m}' #{symbol}"
    else
      m.zero? ? "#{d}° #{symbol}" : "#{m}'"
    end
  end

  def parse_degrees(degrees)
    if degrees =~ /\s/
      d, m, = degrees.delete("'").delete('°').split(/\s/)
      d = d.to_i
      m = m.to_d rescue 0
    else
      deg = degrees.to_d
      d = deg.to_i
      m = ((deg - deg.to_i) * 60)
    end

    negative = d.negative?

    [d.abs, m.abs.round(1), negative]
  end

  def axis_symbol(negative, axis)
    if axis == :ns
      negative ? 'S' : 'N'
    elsif axis == :ew
      negative ? 'E' : 'W'
    end
  end

  def increment_degrees(degrees, increment)
    d, m, neg = parse_degrees(degrees)

    m += increment

    while m >= 60
      m -= 60
      d += 1
    end

    while m < 0
      m += 1
      d -= 1
    end

    "#{neg ? '-' : ''}#{d} #{m}"
  end

  def top_info(name, squadron, sight_number)
    fill_color 'FFFFFF'
    fill_polygon([20, 648], [20, 800], [520, 800], [520, 648])
    fill_polygon([-50, 800], [19, 800], [19, 0], [-50, 0])
    fill_polygon([521, 800], [570, 800], [570, 0], [521, 0])
    fill_color '000099'

    draw_text "Name: #{name}", size: 12, at: [350, 710]
    draw_text "Squadron: #{squadron}", size: 12, at: [350, 680]
    draw_text "Sight # #{sight_number}", size: 12, at: [60, 670]
    draw_text 'Constant Latitude Scale', size: 14, at: [20, 720]
    draw_text 'Small Area Plotting Sheet', size: 12, at: [26, 705]

    image File.join(Rails.root, 'app', 'assets', 'images', 'WHEEL.thumb.png'), at: [230, 740], width: 80
  end

  def coordinates(lat, lon, mid_lat: $sight_data[:latitude], mid_lon: $sight_data[:longitude], increment: $sight_data[:increment])
    min_x = 270 - long_meridians(mid_lat)[:big_long_line]
    max_x = 270 + long_meridians(mid_lat)[:big_long_line]
    min_y = 405 - 81 * 3
    max_y = 405 + 81 * 3

    min_lat = parse_degrees(increment_degrees(mid_lat, increment.to_i * -3))
    max_lat = parse_degrees(increment_degrees(mid_lat, increment.to_i * 3))
    min_lon = parse_degrees(increment_degrees(mid_lon, increment.to_i * -3))
    max_lon = parse_degrees(increment_degrees(mid_lon, increment.to_i * 3))

    min_lat = (min_lat[0] + min_lat[1] / 60)
    max_lat = (max_lat[0] + max_lat[1] / 60)
    min_lon = (min_lon[0] + min_lon[1] / 60)
    max_lon = (max_lon[0] + max_lon[1] / 60)

    lat = parse_degrees(lat)
    lat = (lat[0] + lat[1] / 60)
    lon = parse_degrees(lon)
    lon = (lon[0] + lon[1] / 60)

    raise 'Latitude out of bounds' if lat > max_lat || lat < min_lat
    raise 'Longitude out of bounds' if lon > max_lon || lon < min_lon

    p_lat = ((lat - min_lat) / (max_lat - min_lat)) * (max_y - min_y)
    p_lon = ((lon - min_lon) / (max_lon - min_lon)) * (max_x - min_x)

    [max_x - p_lon, p_lat + 162]
  end

  def point(coords)
    translate(-1.5, -3.5) do
      draw_text '•', size: 10, at: coords
    end
  end

  def plot_circle(coords)
    stroke_circle(coords, 5)
  end

  def track(angle, coords = [270, 405])
    x, y = coords
    translate(x - 270, y - 405) do
      rotate((45 - angle + 1), origin: [270, 405]) do
        stroke { line([20, 162], [520, 648]) }
      end
    end
  end

  def intercept(angle, dist, origin: [270, 405], increment: $sight_data[:increment])
    d = dist.to_d * 81 / increment.to_i
    translate(origin[0] - 270, origin[1] - 405) do
      rotate(360 - angle, origin: [270, 405]) do
        dash([4, 4])
        stroke { line([270, 405], [270, 405 + d]) }
        undash
      end
    end

    [angle, d, origin]
  end

  def lop(intercept, increment: $sight_data[:increment], plot_ep: false)
    angle, dist, (ep_x, ep_y) = intercept

    if dist.negative?
      angle += 180
      angle = angle % 360
    end

    ep = [
      ep_x + dist.abs * Math.sin(angle * Math::PI / 180),
      ep_y + dist.abs * Math.cos(angle * Math::PI / 180)
    ]

    if plot_ep
      rotate(45, origin: ep) do
        translate(-5, -5) do
          stroke do
            rectangle(ep, 10, -10)
          end
        end
      end
    end
    track(angle + 90, ep)

    s_err = dist * increment.to_d / 10

    line = [
      m = -1 * Math.tan(angle * Math::PI / 180),
      ep[1] - (m * ep[0])
    ]
    $lines ||= []
    $lines << line

    [line, s_err]
  end

  def plot_intersection(lines)
    b = lines[1][1] - lines[0][1]
    m = lines[0][0] - lines[1][0]

    x = b / m
    y = lines[0][0] * x + lines[0][1]

    set_colors('000000')
    self.line_width = 0.25
    point([x, y])
    plot_circle([x, y])

    distance_x = ((270 - x) / 81) * $sight_data[:increment].to_i
    distance_y = ((y - 405) / 81) * $sight_data[:increment].to_i
    lat = display_degrees(increment_degrees($sight_data[:latitude], distance_y), axis: :ns, force_degree: true, decimal: true)
    lon = display_degrees(increment_degrees($sight_data[:longitude], distance_x), axis: :ew, force_degree: true, decimal: true)

    draw_text("Fix   #{lat}", size: 10, at: [245, 125])
    draw_text(lon, size: 10, at: [267, 115])
  end
end
