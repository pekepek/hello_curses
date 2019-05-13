# frozen_string_literal: true

require 'curses'
require 'hello_curses/character_color'

module HelloCurses
  class FileEditor
    include Curses

    def initialize(file_name)
      @file_name = file_name
      @data_lines = File.open(file_name, 'a+').readlines
      @cursor_position_x = 0
      @cursor_file_position_y = 0
      @screen_top_file_position_y = 0

      @screen = stdscr

      screen.scrollok(true)
      screen.keypad = true
      noecho
    end

    def edit
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

          case input
          when ':q'
            break
          when ':wq'
            File.open(file_name, 'w') {|f| f.puts data_lines }

            break
          when /\A\/(.+)/
            character_color.change_color!(color: $1)
          end

          noecho

          deleteln

          # NOTE 入力した分とスクロールを戻した分のデータが欠けてしまうので補完
          draw_line(bottom_y, data_lines[screen_top_file_position_y + bottom_y].to_s.chomp)
          draw_line(0, data_lines[screen_top_file_position_y].to_s.chomp)
          open_file
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

    attr_reader :file_name, :screen, :data_lines, :cursor_position_x, :cursor_file_position_y, :screen_top_file_position_y

    def character_color
      @character_color ||= CharacterColor.new
    end

    def cursor_down
      setpos(cursor_position_y, 0)

      return if cursor_file_position_y >= max_data_line

      @cursor_file_position_y += 1

      if cursor_position_y >= screen.maxy
        scroll(1)
      end

      adjust_position_x
    end

    def cursor_up
      setpos(cursor_position_y, 0)

      return if cursor_file_position_y <= 0

      @cursor_file_position_y -= 1

      if cursor_position_y < 0
        return if screen_top_file_position_y.negative?

        scroll(-1)
      end

      adjust_position_x
    end

    def scroll(num)
      screen.scrl(num)
      addstr(data_lines[cursor_file_position_y].to_s.chomp)
      @screen_top_file_position_y += num
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
      data_lines[cursor_file_position_y].to_s.chomp.size
    end

    def set_cursor
      setpos(cursor_position_y, cursor_position_x)
    end

    def cursor_position_y
      cursor_file_position_y - screen_top_file_position_y
    end

    def open_file
      data_lines.each_with_index do |str, i|
        draw_line(i, str)
      end

      @cursor_file_position_y = max_data_line

      top = cursor_file_position_y - screen.maxy + 1
      @screen_top_file_position_y = top.positive? ? top : 0

      refresh
    end

    def max_data_line
      data_lines.count
    end

    def add_newline
      data_lines.insert(cursor_file_position_y + 1, '')

      redraw_under_lines

      cursor_down
    end

    def delete_line
      data_lines.delete_at(cursor_file_position_y + 1)

      redraw_under_lines
    end

    def delete
      str = data_lines[cursor_file_position_y].to_s

      if cursor_position_x.zero?
        return if cursor_file_position_y.zero?

        cursor_up
        @cursor_position_x = max_position_x

        deleted_str = data_lines[cursor_file_position_y].to_s.chomp + str

        data_lines[cursor_file_position_y] = deleted_str
        delete_line
      else
        b = str[0...cursor_position_x-1].to_s
        a = str[cursor_position_x..-1].to_s

        deleted_str = b + a

        data_lines[cursor_file_position_y] = deleted_str
        draw_line(cursor_position_y, deleted_str)
        cursor_left
      end
    end

    def input(char)
      str = data_lines[cursor_file_position_y].to_s

      b = str[0...cursor_position_x].to_s
      a = str[cursor_position_x..-1].to_s

      inputed_str = b + char + a

      data_lines[cursor_file_position_y] = inputed_str
      draw_line(cursor_position_y, inputed_str)
      cursor_right
    end

    def draw_line(postion, data)
      setpos(postion, 0)
      screen.maxx.times { delch }
      addstr(data)
    end

    def redraw_under_lines
      (cursor_position_y...lines).each.with_index(0) do |y, i|
        draw_line(y, data_lines[cursor_file_position_y + i].to_s.chomp)
      end
    end

    def debug
      setpos(lines - 1, 0)
      deleteln
      addstr("cpx:#{cursor_position_x}, cpy:#{cursor_position_y}, dpy:#{cursor_file_position_y}, spy: #{screen_top_file_position_y}")
    end
  end
end
