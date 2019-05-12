require 'hello_curses/version'
require 'curses'

module HelloCurses
  extend self

  class Error < StandardError; end

  def execute
    puts 'HelloCurses'
  end
end
