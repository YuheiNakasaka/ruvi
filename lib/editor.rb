# frozen_string_literal: true

require 'io/console'

class Editor
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
    @input = Input.new(screen: @screen)
  end

  def run
    $stdin.raw do
      loop do
        EscapeCode.clear_screen
        @screen.update_scroll_offset
        @screen.draw_lines
        @input.draw_status_bar
        @screen.update_cursor_position
        result = handle_input
        break if result == :quit
        next if result == :insert
      end
    end
  end

  private

  def handle_input
    if @input.normal?
      @input.handle_normal
    elsif @input.insert?
      @input.handle_insert
    elsif @input.command?
      @input.handle_command
    end
  end
end
