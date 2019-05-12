# frozen_string_literal: true

require 'curses'

module HelloCurses
  class FileViewer
    include Curses

    def initialize(file_name)
      @data_lines = File.readlines(file_name)

      stdscr.scrollok(true)
      stdscr.keypad(true)
      noecho
    end

    def view
      open_file

      while char = get_char
        case char
        when "\e"
          setpos(lines - 1, 0)

          echo

          input = getstr.chomp

          break if input == ':q'
        end

        noecho
      end

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
