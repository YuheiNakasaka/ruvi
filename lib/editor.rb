# frozen_string_literal: true

require 'io/console'

class Editor
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path

    if file_path.nil?
      puts 'No file path provided'
      exit
    end

    unless File.exist?(file_path)
      puts 'File does not exist'
      exit
    end

    @screen = Screen.new(File.readlines(@file_path, chomp: true))
  end

  def run
    render
  end

  private

  def render
    $stdin.raw do
      loop do
        EscapeCode.clear_screen
        @screen.update_scroll_offset
        @screen.draw_lines
        @screen.update_cursor_position
        break if handle_input == :quit
      end
    end
  end

  def handle_input
    input = escaped_input
    case input
    when 'h', "\e[D"
      @screen.move_left
    when 'l', "\e[C"
      @screen.move_right
    when 'j', "\e[B"
      return if @screen.over_bottom?

      @screen.move_down
    when 'k', "\e[A"
      @screen.move_up
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
