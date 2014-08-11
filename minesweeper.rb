class Tile
  attr_accessor :board, :row, :col, :state, :bomb
  
  def initialize(board, row, col)
    @board = board
    @row = row
    @col = col
    @state = :hidden
    @bomb = false
  end
  
  def neighbor_bomb_count
    0
  end
  
end

class Board
  def initialize
    @rows = Array.new(3) { |r| Array.new(3) { |c| Tile.new(self, r, c) } }
  end
  
  def width
    9
  end
  
  def height
    9
  end
  
  def [] pos
    row, col = pos
    Tile.new(self, row, col)
  end
  
end


class Game
  def initialize
    @board = Board.new
  end
  
  def play
    welcome_message
    until game_over?
      display_board
      take_input
      update_board
    end
  end
  
  def welcome_message
    puts "WELCOME TO MINESWEEPER"
  end
  
  def game_over?
    # @board.game_over?
    false
  end
  
  def display_board
    puts((0...@board.height).map do |row|
      (0...@board.width).map do |col|
        tile_to_character @board[ [row, col] ]
      end.join
    end.join("\n"))
  end
  
  
  def tile_to_character tile
    case tile.state
    when :hidden then '*'
    when :flagged then 'F'
    else
      n = tile.neighbor_bomb_count
      n == 0 ? '_' : n.to_s
    end
  end
  
  def take_input
    print "Type in <type> <row> <col>: "
    @move_type, row, col = gets.split
    
    unless ['r','f'].include?(@move_type)
      puts "Invalid move type. Move type must be 'r' or 'f'"
      return take_input
    end
    
    unless row =~ /\a\d+\z/ && col =~ /\a\d+\z/
      puts "Invalid row and/or column"
      puts "Row and column must be integers"
      return take_input
    end
    
    @row, @col = [row, col].map(&:to_i)
    
    unless @row < @board.height
      puts "row must be between 0 and #{@board.height-1}"
      return take_input
    end
    
    unless @col < @board.width
      puts "column must be between 0 and #{@board.width-1}"
      return take_input
    end
  end
  
  def update_board
    case @move_type
    when 'r'
      reveal
    when 'f'
      flag
    else
      puts "command must begin with 'r' or 'f'"
      take_input
    end
  end
  
  def reveal
    puts "Revealing position #{@row}, #{@col}"
    @board.reveal(@row, @col)
  end
  
  def flag
    puts "Flagging position #{@row}, #{@col}"
    @board.flag(@row, @col)
  end
end

game = Game.new
# game.display_board

game.play