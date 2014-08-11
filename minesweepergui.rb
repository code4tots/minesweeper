require_relative 'minesweeper'
require 'time'
require 'gosu'

class GameWindow < Gosu::Window
  attr_accessor :board, :interface
  
  def initialize
    super 640, 480, false
    self.caption = 'Minesweeper'
    @font = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @bigfont = Gosu::Font.new(self, Gosu::default_font_name, 60)
  end
  
  def draw
    @board.height.times do |row|
      @board.width.times do |col|
        draw_cell(row, col, 0xaaffffff)
        
        tile = @board[ [row,col] ]
        
        case tile.state
        when :hidden then draw_hidden(row, col)
        when :flagged then draw_flag(row, col)
        else
          n = tile.neighbor_bomb_count
          if n == 0
            draw_interior(row, col)
          else
            draw_number(row, col, n)
          end
        end
      end
    end
    
    draw_message(
      @first_click.nil? ?
        0.0 :
        @board.game_over? ?
          @end_time - @start_time :
          Time.now - @start_time, 0, 100, 0x55ffffff)
    
    unless @message.nil?
      draw_message(@message)
    end
  end
  
  def needs_cursor?
    true
  end
  
  def draw_hidden(row, col)
    draw_cell(row, col, 0xaaffffff)
  end
  
  def draw_interior(row, col)
    draw_cell(row, col, 0xff0000ff)
  end
  
  def draw_flag(row, col)
    draw_cell(row, col, 0xffff0000)
  end
  
  def draw_number(row, col, n)
    @font.draw(n.to_s,
      cell_width * (col+0.3),
      cell_height * (row+0.2),
      0xff000000)
  end
  
  def draw_cell(row, col, color)
    dx = 5
    draw_quad(
      col * cell_width + dx,
      row * cell_height + dx,
      color,
      
      (col+1) * cell_width - dx,
      row * cell_height + dx,
      color,
      
      (col+1) * cell_width - dx,
      (row+1) * cell_height - dx,
      color,
      
      col * cell_width + dx,
      (row+1) * cell_height - dx,
      color)
  end
  
  def button_down(id)
    return nil if @interface.game.game_over?
    
    if @first_click.nil?
      @start_time = Time.now
      @first_click = true
    end
    
    case id
    when Gosu::MsLeft
      reveal
    when Gosu::MsRight
      flag
    end
  end
  
  def reveal
    find_coordinates
    @interface.game.reveal
    if @interface.game.game_over?
      @end_time = Time.now
      if @interface.game.board.game_won?
        set_victory_message
      else
        set_defeat_message
      end
    end
  end
  
  def set_victory_message
    @message = 'victory'
  end
  
  def set_defeat_message
    @message = 'defeat'
  end
  
  def draw_message(message, dx = 0, dy = 0, color = 0xff000000)
    @bigfont.draw(message,
      width / 2 + dx,
      height / 2 + dy,
      color)
  end
  
  def flag
    find_coordinates
    @interface.game.flag
  end
  
  def find_coordinates
    @interface.game.row = mouse_y / cell_height
    @interface.game.col = mouse_x / cell_width
  end
  
  def cell_width
    width.to_f / @board.width
  end
  
  def cell_height
    height.to_f / @board.height
  end
end

class GuiInterface < UserInterface
  attr_reader :game
  def initialize(save_filename = nil)
    super
    @window = GameWindow.new
    @window.board = @game.board
    @window.interface = self
  end
  
  def play
    @window.show
  end
  
end

if __FILE__ == $PROGRAM_NAME
  GuiInterface.new.play
end

