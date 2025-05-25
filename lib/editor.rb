# frozen_string_literal: true

require 'io/console'

class Editor
  attr_reader :file_path
  attr_accessor :x,
                :y,
                :lines,
                :wrapped_lines,
                :row_count,
                :col_count,
                :scroll_offset,
                :visible_height

  def initialize(file_path)
    @file_path = file_path
    @x = 1
    @y = 0
    @scroll_offset = 0
    @row_count, @col_count = IO.console.winsize
    @visible_height = @row_count - 1
    @lines = File.readlines(@file_path, chomp: true)
    @wrapped_lines = @lines.flat_map { |line| wrap_line(line, @col_count) }

    if file_path.nil?
      puts 'No file path provided'
      return
    end

    return if File.exist?(file_path)

    puts 'File does not exist'
  end

  def run
    render
  end

  private

  def render
    $stdin.raw do
      loop do
        clear_screen
        update_window_size
        update_scroll_offset
        draw_lines
        @x, y = update_cursor_position
        move_cursor(@x, y)
        break if handle_input == :quit
      end
    end
  end

  def clear_screen
    print "\e[2J"
    print "\e[H"
  end

  def update_window_size
    @row_count, @col_count = IO.console.winsize
  end

  def update_scroll_offset
    @wrapped_lines = @lines.flat_map { |line| wrap_line(line, @col_count) }
    @scroll_offset = [[0, @scroll_offset].max, @wrapped_lines.size - @visible_height].min
  end

  def wrap_line(line, width)
    return [''] if line.nil? || line.empty?

    line.scan(/.{1,#{width}}|.+/)
  end

  def visible_lines
    @visible_lines = @wrapped_lines[@scroll_offset, @visible_height] || []
  end

  def draw_lines
    visible_lines.each_with_index do |line, i|
      move_cursor(1, i + 1)
      print line.ljust(@col_count)
    end
    print "\e[#{@visible_height + 1};1H"
    print "row: #{@y}/#{@lines.size} col: #{@x}/#{@col_count + 1} offset: #{@scroll_offset}".rjust(@col_count)
  end

  def update_cursor_position
    @y = [[0, @y].max, @wrapped_lines.size - 1].min
    @x = [[1, @x].max, @col_count].min
    relative_cursor_y = @y - @scroll_offset
    [@x, relative_cursor_y + 1]
  end

  def move_cursor(x, y)
    print "\e[#{y};#{x}H"
  end

  def handle_input
    input = escaped_input
    case input
    when 'h', "\e[D"
      @x = [1, @x - 1].max
    when 'l', "\e[C"
      @x += 1
    when 'j', "\e[B"
      return if @y >= @lines.size

      @y += 1
      @scroll_offset += 1 if @y >= @scroll_offset + @visible_height - 1
    when 'k', "\e[A"
      @y = [1, @y - 1].max
      @scroll_offset -= 1 if @y < @scroll_offset
    when 'q'
      :quit
    end
  end

  def escaped_input
    input = $stdin.getch
    case input
    when "\e"
      input << $stdin.getch
      input << $stdin.getch
    else
      input
    end
  end
end
