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

  def delete_char
    line_index, line, pos = char_position
    @lines[line_index] = "#{line.dup.slice(0, pos)}#{line.dup.slice(pos + 1..-1)}"
    @abs_x = [@abs_x - 1, 1].max
  end

  def delete_line
    return if @lines.empty?

    current_line_index, _wrap_index = @line_map[@abs_y] || [0, 0]
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
    File.write(file_path, @lines.join("\n"))
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
    line_index, wrap_index = @line_map[@abs_y]
    line = @lines[line_index]
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
end
