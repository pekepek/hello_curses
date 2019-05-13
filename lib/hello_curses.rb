# frozen_string_literal: true

require 'hello_curses/version'
require 'hello_curses/file_editor'

module HelloCurses
  extend self

  class Error < StandardError; end

  def execute(file_name)
    FileEditor.new(file_name).edit
  end
end
