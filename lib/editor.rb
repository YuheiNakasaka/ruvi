# frozen_string_literal: true

require 'io/console'

class Editor
  attr_reader :file_path
  attr_accessor :x, :y, :row_count, :col_count

  def initialize(file_path)
    @file_path = file_path
    @x = 1
    @y = 1
    @row_count, @col_count = IO.console.winsize
    @lines = File.readlines(@file_path, chomp: true)

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
        draw_lines
        update_cursor_position
        move_cursor(@x, @y)
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

  def draw_lines
    visible_lines.each_with_index do |line, i|
      move_cursor(1, i + 1)
      print line.ljust(@col_count)
    end
  end

  def visible_lines
    @lines[0...(@row_count - 1)]
  end

  def update_cursor_position
    @y = [[1, @y].max, visible_lines.size].min
    @x = [[1, @x].max, @col_count].min
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
      @y += 1
    when 'k', "\e[A"
      @y = [1, @y - 1].max
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
