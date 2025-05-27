# frozen_string_literal: true

module EscapeCode
  def self.move_to(x, y)
    print "\e[#{y};#{x}H"
  end

  def self.clear_screen
    print "\e[2J"
    print "\e[H"
  end
end
