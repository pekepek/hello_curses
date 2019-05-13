# frozen_string_literal: true

require 'curses'

module HelloCurses
  class CharacterColor
    include  Curses

    Color = Struct.new(:number, :char_color, :bg_color)

    COLORS = {
      white: Color.new(1, COLOR_WHITE, COLOR_BLACK),
      pink: Color.new(2, COLOR_MAGENTA, COLOR_BLACK),
      red: Color.new(3, COLOR_RED, COLOR_BLACK),
      yellow: Color.new(4, COLOR_YELLOW, COLOR_BLACK),
      green: Color.new(5, COLOR_GREEN, COLOR_BLACK),
      l_blue: Color.new(6, COLOR_CYAN, COLOR_BLACK),
      blue: Color.new(7, COLOR_BLUE, COLOR_BLACK),
      black: Color.new(8, COLOR_BLACK, COLOR_WHITE)
    }

    attr_reader :color

    def initialize
      start_color

      COLORS.each do |_, color|
        init_pair(*color.values)
      end
    end

    def change_color!(color:)
      return unless COLORS.keys.include?(color.to_sym)

      attrset(color_pair(COLORS[color.to_sym].number))
    end
  end
end
