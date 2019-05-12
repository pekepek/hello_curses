# frozen_string_literal: true

require 'curses'

module HelloCurses
  class FileViewer
    include Curses

    def initialize(file_name)
      @data_lines = File.readlines(file_name)
      @cursor_position_x = 0
      @cursor_position_y = 0

      stdscr.scrollok(true)
      stdscr.keypad = true
      noecho
    end

    def view
      open_file

      while char = get_char
        case char
        when Key::DOWN
          cursor_down
        when Key::UP
          cursor_up
        when Key::RIGHT
          cursor_right
        when Key::LEFT
          cursor_left
        when "\e"
          setpos(lines - 1, 0)

          echo

          input = getstr.chomp

          break if input == ':q'
        end

        noecho
        set_cursor
      end

      close_screen
    end

    private

    attr_reader :data_lines, :cursor_position_x, :cursor_position_y

    def cursor_down
      @cursor_position_y += 1
    end

    def cursor_up
      @cursor_position_y -= 1
    end

    def cursor_right
      @cursor_position_x += 1
    end

    def cursor_left
      @cursor_position_x -= 1
    end

    def set_cursor
      setpos(cursor_position_y, cursor_position_x)
    end

    def open_file
      data_lines.each_with_index do |str, idx|
        setpos(idx, 0)

        addstr(str)
      end

      refresh
      set_cursor
    end
  end
end
