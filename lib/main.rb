# frozen_string_literal: true

require_relative 'editor'
require_relative 'screen'
require_relative 'escape_code'

def main
  args = ARGV
  file_path = args[0]
  editor = Editor.new(file_path)
  editor.run
end
