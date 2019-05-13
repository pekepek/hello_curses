# frozen_string_literal: true

require 'curses'

module HelloCurses
  class FileEditor
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
        when "\u007F"
          delete
        when /\r\Z/, /\n\Z/
          add_newline
        else
          input(char)
        end

        set_cursor
      end

      close_screen
    end

    private

    attr_reader :screen, :data_lines, :cursor_position_x, :data_position_y, :screen_position_y

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
      data_lines[data_position_y].to_s.chomp.size
    end

    def set_cursor
      setpos(cursor_position_y, cursor_position_x)
    end

    def cursor_position_y
      data_position_y - screen_position_y
    end

    def open_file
      data_lines.each_with_index do |str, i|
        setpos(i, 0)

        addstr(str)
      end

      @data_position_y = max_data_line
      @screen_position_y = data_position_y - screen.maxy + 1

      refresh
    end

    def max_data_line
      data_lines.count
    end

    def add_newline
      data_lines.insert(data_position_y + 1, '')

      redraw_under_lines

      cursor_down
    end

    def delete
      str = data_lines[data_position_y].to_s

      if cursor_position_x.zero?
        return if data_position_y.zero?

        cursor_up
        @cursor_position_x = max_position_x

        data_lines[data_position_y] = data_lines[data_position_y].to_s.chomp + str

        data_lines.delete_at(data_position_y + 1)

        redraw_under_lines
      else
        b = str[0...cursor_position_x-1].to_s
        a = str[cursor_position_x..-1].to_s

        data_lines[data_position_y] = b + a

        redraw_line
        cursor_left
      end

      debug
    end

    def input(char)
      str = data_lines[data_position_y].to_s

      b = str[0...cursor_position_x].to_s
      a = str[cursor_position_x..-1].to_s

      data_lines[data_position_y] = b + char + a

      redraw_line
      cursor_right
    end

    def redraw_line
      setpos(cursor_position_y, 0)
      delch
      addstr(data_lines[data_position_y].to_s)
    end

    def redraw_under_lines
      (cursor_position_y...lines).each.with_index(0) do |y, i|
        setpos(y, 0)

        screen.maxx.times { delch }
        addstr(data_lines[data_position_y + i].to_s.chomp)
      end
    end

    def debug
      setpos(lines - 1, 0)
      deleteln
      addstr("cpx:#{cursor_position_x}, cpy:#{cursor_position_y}, dpy:#{data_position_y}, spy: #{screen_position_y}")
    end
  end
end
