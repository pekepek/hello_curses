# frozen_string_literal: true

require 'curses'

module HelloCurses
  class FileViewer
    include Curses

    def initialize(file_name)
      @data_lines = File.readlines(file_name)
      @cursor_position_x = 0
      @data_position_y = 0
      @screen_position_y = 0

      @screen = stdscr

      screen.scrollok(true)
      screen.keypad = true
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

          deleteln
          noecho
        end

        set_cursor
      end

      close_screen
    end

    private

    attr_reader :screen, :data_lines, :cursor_position_x, :data_position_y, :screen_position_y, :max_data_line

    def cursor_down
      return if data_position_y > max_data_line

      @data_position_y += 1

      if cursor_position_y >= screen.maxy
        screen.scrl(1)
        addstr(data_lines[data_position_y].to_s.chomp)
        @screen_position_y += 1
      end
    end

    def cursor_up
      return if data_position_y < 0

      @data_position_y -= 1

      if cursor_position_y < 0
        screen.scrl(-1)
        addstr(data_lines[data_position_y + 1].to_s.chomp)
        @screen_position_y -= 1
      end
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

    def cursor_position_y
      data_position_y - screen_position_y - 1
    end

    def open_file
      data_lines.each_with_index do |str, idx|
        setpos(idx, 0)

        addstr(str)
      end

      @max_data_line = data_lines.count - 1
      @data_position_y = max_data_line
      @screen_position_y = data_position_y - screen.maxy

      refresh
    end
  end
end
