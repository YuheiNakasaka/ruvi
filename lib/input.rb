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

  def search_down?
    @mode == :search_down
  end

  def search_up?
    @mode == :search_up
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
    when '^'
      @screen.move_head
    when '$'
      @screen.move_tail
    when "\u0006"
      @screen.move_page_down
    when "\u0002"
      @screen.move_page_up
    when 'i'
      @mode = :insert
    when 'x'
      @screen.delete_char
    when 'dd'
      @screen.delete_line
    when '/'
      clear_command
      @mode = :search_down
    when '?'
      clear_command
      @mode = :search_up
    when 'n'
      @screen.search_down(command_text)
    when 'N'
      @screen.search_up(command_text)
    when ':'
      clear_command
      @mode = :command
    end
  end

  def handle_insert
    input = escaped_input
    return @mode = :normal if input == "\e"

    # 矢印移動だけはサポート
    case input
    when "\e[D"
      @screen.move_left
    when "\e[C"
      @screen.move_right
    when "\e[B"
      return if @screen.over_bottom?

      @screen.move_down
    when "\e[A"
      @screen.move_up
    when "\n", "\r"
      @screen.insert_newline
    else
      return if input.start_with?("\e")

      @screen.insert_char(input)
    end
  end

  def handle_command
    input = $stdin.getch
    if input == "\e"
      @mode = :normal
      clear_command
    elsif ["\n", "\r"].include?(input)
      resp = case command_text
             when 'q'
               :quit
             when 'wq!'
               :write_quit_force
             when 'q!'
               :quit_force
             else
               :unknown_command
             end
      clear_command
      resp
    else
      @command << input
    end
  end

  def handle_search
    input = $stdin.getch
    if input == "\e"
      @mode = :normal
      clear_command
    elsif ["\n", "\r"].include?(input)
      if search_down?
        @screen.search_down(command_text)
      elsif search_up?
        @screen.search_up(command_text)
      end
      @mode = :normal
    else
      @command << input
    end
  end

  def draw_status_bar(message: '')
    print "\e[#{@screen.visible_height + 1};1H"

    unless message.empty?
      print message.ljust(@screen.visible_width)
      return
    end

    if insert?
      print '--- INSERT ---'.ljust(@screen.visible_width)
    elsif command?
      print ":#{command_text}".ljust(@screen.visible_width)
    elsif search_down?
      print "/#{command_text}".ljust(@screen.visible_width)
    elsif search_up?
      print "?#{command_text}".ljust(@screen.visible_width)
    else
      print ''.ljust(@screen.visible_width)
    end
  end

  def to_command_mode
    loop do
      input = escaped_input
      case input
      when ':'
        @mode = :command
        break
      end
    end
    clear_command
  end

  private

  def command_text
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
    when normal? && 'd'
      input << $stdin.getch
    else
      input
    end
  end
end
