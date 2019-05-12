# frozen_string_literal: true

require 'hello_curses/version'
require 'hello_curses/file_viewer'

module HelloCurses
  extend self

  class Error < StandardError; end

  def execute(file_name)
    FileViewer.new(file_name).view
  end
end
