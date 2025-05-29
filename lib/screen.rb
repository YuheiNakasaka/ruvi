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
  end

  def init_logical_lines
    @display_lines = []
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
    @abs_y = [[0, @abs_y].max, @total_display_lines].min
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

  def over_bottom?
    @abs_y >= @lines.size
  end

  def insert_char(input)
    line_index, wrap_index = @line_map[@abs_y]
    line = @lines[line_index]
    insert_pos = (wrap_index * @col) + @abs_x - 1
    insert_pos = [line.size, insert_pos].min
    @lines[line_index] = line.dup.insert(insert_pos, input)
    @abs_x += 1
  end

  def delete_char
    line_index, wrap_index = @line_map[@abs_y]
    line = @lines[line_index]
    delete_pos = (wrap_index * @col) + @abs_x - 1
    delete_pos = [line.size, delete_pos].min
    @lines[line_index] = "#{line.dup.slice(0, delete_pos)}#{line.dup.slice(delete_pos + 1..-1)}"
    @abs_x = [@abs_x - 1, 1].max
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
end
