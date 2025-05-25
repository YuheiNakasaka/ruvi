# frozen_string_literal: true

require 'io/console'

class Editor
  attr_reader :file_path
  attr_accessor :x, :y

  def initialize(file_path)
    @file_path = file_path
    @x = 1
    @y = 1

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
    lines = File.readlines(@file_path, chomp: true)
    $stdin.raw do
      loop do
        clear_screen
        draw_lines(lines)
        move_cursor(@x, @y)
        break if handle_input == :quit
      end
    end
  end

  def clear_screen
    print "\e[2J"
    print "\e[H"
  end

  def draw_lines(lines)
    lines.each_with_index do |line, i|
      move_cursor(1, i + 1)
      print line.ljust(80)
    end
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
