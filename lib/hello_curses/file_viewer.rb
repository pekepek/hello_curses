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
        # TODO スクロールが必要ないファイル行数の場合にバグっている
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
          bottom_y = lines - 1

          setpos(bottom_y, 0)
          echo

          # NOTE getstr の Enter で一つスクロールしてしまうので戻す
          input = getstr.chomp
          screen.scrl(-1)

          break if input == ':q'

          noecho

          # NOTE 入力した分とスクロールを戻した分のデータが欠けてしまうので補完
          addstr(data_lines[screen_position_y + bottom_y + 1].to_s.chomp)
          setpos(0, 0)
          addstr(data_lines[screen_position_y + 1].to_s.chomp)
        end

        set_cursor
      end

      close_screen
    end

    private

    attr_reader :screen, :data_lines, :cursor_position_x, :data_position_y, :screen_position_y, :max_data_line

    def cursor_down
      setpos(cursor_position_y, 0)

      return if data_position_y >= max_data_line

      @data_position_y += 1

      if cursor_position_y >= screen.maxy
        screen.scrl(1)
        addstr(data_lines[data_position_y].to_s.chomp)
        @screen_position_y += 1
      end

      adjust_position_x
    end

    def cursor_up
      setpos(cursor_position_y, 0)

      return if data_position_y <= 0

      @data_position_y -= 1

      if cursor_position_y < 0
        return if screen_position_y.negative?

        screen.scrl(-1)
        addstr(data_lines[data_position_y].to_s.chomp)
        @screen_position_y -= 1
      end

      adjust_position_x
    end

    def adjust_position_x
      return if cursor_position_x <= max_position_x

      @cursor_position_x = max_position_x
    end

    def cursor_right
      return if max_position_x == cursor_position_x

      @cursor_position_x += 1
    end

    def cursor_left
      return if cursor_position_x.zero?

      @cursor_position_x -= 1
    end

    def max_position_x
      data_lines[data_position_y].to_s.chomp.size - 1
    end

    def set_cursor
      setpos(cursor_position_y, cursor_position_x)
    end

    def cursor_position_y
      data_position_y - screen_position_y
    end

    def open_file
      data_lines.each_with_index do |str, idx|
        setpos(idx, 0)

        addstr(str)
      end

      @max_data_line = data_lines.count
      @data_position_y = max_data_line
      @screen_position_y = data_position_y - screen.maxy + 1

      refresh
    end
  end
end
