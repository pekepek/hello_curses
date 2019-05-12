# frozen_string_literal: true

require 'curses'

module HelloCurses
  class FileViewer
    include  Curses

    def initialize(file_name)
      @data_lines = File.readlines(file_name)

      stdscr.scrollok(true)
      stdscr.keypad(true)
    end

    def view
      open_file

      get_char
      close_screen
    end

    private

    attr_reader :data_lines

    def open_file
      data_lines.each_with_index do |str, idx|
        setpos(idx, 0)

        addstr(str)
      end

      refresh
    end
  end
end
