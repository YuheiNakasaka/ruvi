# frozen_string_literal: true

class Screen
  attr_reader :visible_height,
              :visible_width

  def initialize(lines)
    @abs_x = 1
    @abs_y = 0
    @row, @col = IO.console.winsize
    @scroll_offset = 0
    @visible_width = @col
    @visible_height = @row - 1
    @total_display_lines = 0
    @lines = lines
    @display_lines = []
    @line_map = [] # [[元の行数, 折り返した行数]]
    @editted = false
  end

  def init_logical_lines
    @display_lines = []
    @line_map = []

    # 空ファイルの場合は空行を1つ追加
    @lines = [''] if @lines.empty?

    @lines.each_with_index do |line, i|
      wraps = wrap_line(line, @col)
      wraps.each_with_index do |wrap, j|
        @display_lines << wrap
        @line_map << [i, j]
      end
    end
  end

  def update_scroll_offset
    @total_display_lines = @display_lines.size
    @scroll_offset = [[0, @scroll_offset].max, @total_display_lines - @visible_height].min
  end

  def clear_screen
    EscapeCode.clear_screen
  end

  def draw_lines
    visible_lines.each_with_index do |line, i|
      EscapeCode.move_to(1, i + 1)
      print line.ljust(visible_width)
    end
  end

  def update_cursor_position
    max_y = [@total_display_lines - 1, 0].max
    @abs_y = [[0, @abs_y].max, max_y].min
    @abs_x = [[1, @abs_x].max, @col].min
    relative_cursor_y = @abs_y - @scroll_offset
    EscapeCode.move_to(@abs_x, relative_cursor_y + 1)
  end

  def move_left
    @abs_x = [1, @abs_x - 1].max
  end

  def move_right
    current_display_line_index = @abs_y
    return if current_display_line_index >= @display_lines.size

    current_line = @display_lines[current_display_line_index] || ''
    max_x = current_line.length + 1
    @abs_x = [@abs_x + 1, max_x].min
  end

  def move_down
    @abs_y += 1
    @scroll_offset += 1 if @abs_y >= @scroll_offset + @visible_height - 1
    adjust_x_position
  end

  def move_up
    @abs_y = [0, @abs_y - 1].max
    @scroll_offset -= 1 if @abs_y < @scroll_offset
    adjust_x_position
  end

  def move_head
    @abs_x = 1
  end

  def move_tail
    @abs_x = @display_lines[@abs_y].length + 1
  end

  def move_page_down
    @abs_y = [@abs_y + @visible_height, @total_display_lines].min
    @scroll_offset = [[0, @scroll_offset + @visible_height].max, @total_display_lines - @visible_height].min
    adjust_x_position
  end

  def move_page_up
    @abs_y = [0, @abs_y - @visible_height].max
    @scroll_offset = [[0, @scroll_offset - @visible_height].max, @total_display_lines - @visible_height].min
    adjust_x_position
  end

  def over_bottom?
    @abs_y >= @lines.size
  end

  def dirty?
    @editted
  end

  def insert_char(input)
    line_index, line, pos = char_position
    @lines[line_index] = line.dup.insert(pos, input)
    @abs_x += 1
    @editted = true
  end

  def insert_newline
    line_index, line, pos = char_position
    left_part = line[0...pos]
    right_part = line[pos..] || ''

    @lines[line_index] = left_part
    @lines.insert(line_index + 1, right_part)

    @abs_y += 1
    @abs_x = 1
    @editted = true
  end

  def delete_char
    line_index, line, pos = char_position
    @lines[line_index] = "#{line.dup.slice(0, pos)}#{line.dup.slice(pos + 1..-1)}"
    @abs_x = [@abs_x - 1, 1].max
  end

  def delete_line
    return if @lines.empty?

    current_line_index, = @line_map[@abs_y] || [0, 0]
    @lines.delete_at(current_line_index)
    @editted = true

    if @lines.empty?
      @abs_y = 0
      @abs_x = 1
      return
    end

    @abs_y = if current_line_index >= @lines.size
               find_last_display_line_of_source_line(@lines.size - 1)
             else
               find_first_display_line_of_source_line(current_line_index)
             end
    @abs_x = 1
  end

  def save_file(file_path)
    content = @lines.empty? ? '' : @lines.join("\n")
    File.write(file_path, content)
  end

  def search_down(pattern)
    return if pattern.empty?

    begin
      regex = Regexp.new(pattern, Regexp::IGNORECASE)
    rescue RegexpError
      return
    end

    current_line_index, = @line_map[@abs_y] || [0, 0]
    current_pos = char_position[2]

    current_line = @lines[current_line_index] || ''
    match = current_line.match(regex, current_pos + 1)
    if match
      move_to_match(current_line_index, match.offset(0)[0])
      return
    end

    @lines[(current_line_index + 1)..].each_with_index do |line, i|
      match = line.match(regex)
      if match
        move_to_match(current_line_index + 1 + i, match.offset(0)[0])
        return
      end
    end

    @lines[0..current_line_index].each_with_index do |line, i|
      match = line.match(regex)
      if match
        move_to_match(i, match.offset(0)[0])
        return
      end
    end
  end

  def search_up(pattern)
    return if pattern.empty?

    begin
      regex = Regexp.new(pattern, Regexp::IGNORECASE)
    rescue RegexpError
      return
    end

    current_line_index, = @line_map[@abs_y] || [0, 0]
    current_pos = char_position[2]

    current_line = @lines[current_line_index] || ''
    if current_pos.positive?
      line_part = current_line[0...current_pos]
      matches = []
      line_part.scan(regex) { matches << [Regexp.last_match.offset(0)[0], ::Regexp.last_match(0)] }
      unless matches.empty?
        move_to_match(current_line_index, matches.last[0])
        return
      end
    end

    @lines[0...current_line_index].reverse.each_with_index do |line, i|
      matches = []
      line.scan(regex) { matches << [Regexp.last_match.offset(0)[0], ::Regexp.last_match(0)] }
      next if matches.empty?

      actual_line_index = current_line_index - 1 - i
      move_to_match(actual_line_index, matches.last[0])
      return
    end

    @lines[current_line_index..].reverse.each_with_index do |line, i|
      matches = []
      line.scan(regex) { matches << [Regexp.last_match.offset(0)[0], ::Regexp.last_match(0)] }
      next if matches.empty?

      actual_line_index = @lines.size - 1 - i
      move_to_match(actual_line_index, matches.last[0])
      return
    end
  end

  private

  def adjust_x_position
    return if @abs_y >= @display_lines.size

    current_line = @display_lines[@abs_y] || ''
    max_x = current_line.length + 1
    @abs_x = [@abs_x, max_x].min
  end

  def visible_lines
    @display_lines[@scroll_offset, @visible_height] || []
  end

  def wrap_line(line, width)
    return [''] if line.nil? || line.empty?

    line.scan(/.{1,#{width}}|.+/)
  end

  def char_position
    return [0, '', 0] if @line_map.empty? || @abs_y >= @line_map.size

    line_index, wrap_index = @line_map[@abs_y]
    line = @lines[line_index] || ''
    pos = (wrap_index * @col) + @abs_x - 1
    pos = [line.size, pos].min
    [line_index, line, pos]
  end

  def find_first_display_line_of_source_line(source_line_index)
    [display_line_index(source_line_index) - 1, @total_display_lines - 1].min
  end

  def find_last_display_line_of_source_line(source_line_index)
    [display_line_index(source_line_index) - 1, 0].max
  end

  def display_line_index(source_line_index)
    index = 0
    (0..source_line_index).each do |i|
      line = @lines[i] || ''
      wraps = wrap_line(line, @col)
      index += wraps.size
    end
    index
  end

  def move_to_match(line_index, char_pos)
    @abs_x = char_pos + 1

    display_line_index = 0
    (0...line_index).each do |i|
      line = @lines[i] || ''
      wraps = wrap_line(line, @col)
      display_line_index += wraps.size
    end

    wrap_index = char_pos / @col
    display_line_index += wrap_index
    @abs_x = (char_pos % @col) + 1

    @abs_y = display_line_index

    if @abs_y < @scroll_offset
      @scroll_offset = @abs_y
    elsif @abs_y >= @scroll_offset + @visible_height
      @scroll_offset = @abs_y - @visible_height + 1
    end

    @scroll_offset = [[0, @scroll_offset].max, [@total_display_lines - @visible_height, 0].max].min
  end
end
