# frozen_string_literal: true

require 'timeout'

class Input
  def initialize(screen:)
    @screen = screen
    @mode = :normal
    @command = []
  end

  def normal?
    @mode == :normal
  end

  def insert?
    @mode == :insert
  end

  def command?
    @mode == :command
  end

  def handle_normal
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
    when ':'
      @mode = :command
    when 'q'
      :quit
    end
  end

  def handle_insert
    input = escaped_input
    @mode = :normal if input == "\e"
  end

  def handle_command
    input = $stdin.getch
    if input == "\e"
      @mode = :normal
      clear_command
    elsif ["\n", "\r"].include?(input)
      resp = case command
             when 'q'
               :quit
             when 'w'
               :write
             when 'wq'
               :write_quit
             when 'wq!'
               :write_quit_force
             when 'q!'
               :quit_force
             end
      clear_command
      resp
    else
      @command << input
    end
  end

  def draw_status_bar
    print "\e[#{@screen.visible_height + 1};1H"
    if insert?
      print '--- INSERT ---'.ljust(@screen.visible_width)
    elsif command?
      print ":#{command}".ljust(@screen.visible_width)
    else
      print ''.ljust(@screen.visible_width)
    end
  end

  private

  def command
    @command.join
  end

  def clear_command
    @command = []
  end

  def escaped_input
    input = $stdin.getch
    case input
    when "\e"
      # escと矢印キーの組み合わせを切り分ける処理。雑〜。
      Timeout.timeout(0.01) do
        input << $stdin.read_nonblock(2)
      rescue IO::WaitReadable, EOFError
        input
      rescue Timeout::Error
        input
      end
    else
      input
    end
  end
end
