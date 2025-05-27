# frozen_string_literal: true

class Screen
  attr_reader :lines,
              :display_lines
  attr_accessor :abs_x,
                :abs_y,
                :row,
                :col,
                :scroll_offset,
                :visible_height,
                :visible_width

  def initialize(lines)
    @abs_x = 1
    @abs_y = 0
    @row, @col = IO.console.winsize
    @scroll_offset = 0
    @visible_width = @col
    @visible_height = @row - 1
    @lines = lines
    @display_lines = @lines.flat_map { |line| wrap_line(line, @col) }
  end

  def row_counter
    "#{abs_y}/#{lines.size}"
  end

  def col_counter
    "#{@abs_x}/#{@col + 1}"
  end

  def visible_lines
    @display_lines[@scroll_offset, @visible_height] || []
  end

  def wrap_line(line, width)
    return [''] if line.nil? || line.empty?

    line.scan(/.{1,#{width}}|.+/)
  end

  def draw_lines
    visible_lines.each_with_index do |line, i|
      EscapeCode.move_to(1, i + 1)
      print line.ljust(visible_width)
    end
    print "\e[#{visible_height + 1};1H"
    print "row: #{row_counter} col: #{col_counter} offset: #{scroll_offset}".rjust(visible_width)
  end

  def update_window_size
    @row, @col = IO.console.winsize
  end

  def update_scroll_offset
    @display_lines = @lines.flat_map { |line| wrap_line(line, @col) }
    @scroll_offset = [[0, @scroll_offset].max, @display_lines.size - @visible_height].min
  end

  def update_cursor_position
    @abs_y = [[0, @abs_y].max, @display_lines.size - 1].min
    @abs_x = [[1, @abs_x].max, @col].min
    relative_cursor_y = @abs_y - @scroll_offset
    EscapeCode.move_to(@abs_x, relative_cursor_y + 1)
  end

  def move_left
    @abs_x = [1, @abs_x - 1].max
  end

  def move_right
    @abs_x = [@abs_x + 1, @visible_width].min
  end

  def move_down
    @abs_y += 1
    @scroll_offset += 1 if @abs_y >= @scroll_offset + @visible_height - 1
  end

  def move_up
    @abs_y = [1, @abs_y - 1].max
    @scroll_offset -= 1 if @abs_y < @scroll_offset
  end

  def over_bottom?
    @abs_y >= @lines.size
  end
end
