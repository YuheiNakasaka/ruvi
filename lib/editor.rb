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
    receive_user_input
  end

  private

  def receive_user_input
    lines = File.readlines(@file_path, chomp: true)

    $stdin.raw do
      loop do
        system('clear')
        lines.each { |line| puts line }

        move_cursor(@x, @y)
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
          break
        end
      end
    end
  end

  def move_cursor(x, y)
    print "\e[#{y};#{x}H"
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
