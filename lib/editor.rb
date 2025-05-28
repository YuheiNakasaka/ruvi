# frozen_string_literal: true

require 'io/console'

class Editor
  attr_reader :file_path, :screen
  attr_accessor :mode

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
    @mode = :normal
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
        @screen.draw_status_bar(@mode)
        @screen.update_cursor_position
        result = handle_input
        break if result == :quit
        next if result == :insert
      end
    end
  end

  def handle_input
    if @mode == :normal
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
      when 'i'
        @mode = :insert
      when 'q'
        :quit
      end
    elsif @mode == :insert
      input = $stdin.getch
      @mode = :normal if input == "\e"
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
