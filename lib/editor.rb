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
        @screen.init_logical_lines
        @screen.update_scroll_offset
        @screen.clear_screen
        @screen.draw_lines
        @input.draw_status_bar
        @screen.update_cursor_position

        case handle_input
        when :insert
          next
        when :quit_force
          break
        when :quit
          break unless @screen.dirty?

          @input.draw_status_bar(message: ': No write since last change (add ! to override)')
          @input.to_command_mode
        when :write_quit_force
          @screen.save_file(@file_path)
          break
        else
          next
        end
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
