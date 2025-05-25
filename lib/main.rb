# frozen_string_literal: true

def main
  args = ARGV
  file_path = args[0]

  if file_path.nil?
    puts 'No file path provided'
    return
  end

  unless File.exist?(file_path)
    puts 'File does not exist'
    return
  end

  lines = File.readlines(file_path, chomp: true)
  lines.each_with_index do |line, index|
    puts "#{index + 1}: #{line}"
  end
end
