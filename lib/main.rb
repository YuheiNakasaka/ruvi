# frozen_string_literal: true

require_relative 'editor'

def main
  args = ARGV
  file_path = args[0]
  editor = Editor.new(file_path)
  editor.run
end
