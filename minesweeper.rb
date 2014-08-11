require 'yaml'

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
    neighbors.select { |tile| tile.bomb }.size
  end
  
  def neighbors
    [-1, 0, 1].product([-1, 0, 1]).map do |dr, dc|
      r = @row + dr
      c = @col + dc
      if @board.within_bounds([r,c])
        @board[[r,c]]
      else
        nil
      end
    end.compact
  end
end

class Board
  def initialize(nrows = 9, ncols = 9, nmines = 10)
    @nrows = nrows
    @ncols = ncols
    @nmines = nmines
    @rows = Array.new(height) do |r|
      Array.new(width) do |c|
        Tile.new(self, r, c)
      end
    end
    
    (0...height).to_a.product((0...width).to_a).sample(nmines).each do |r,c|
      @rows[r][c].bomb = true
    end
    
    @revealed_bomb = false
  end
  
  def width
    @ncols
  end
  
  def height
    @nrows
  end
  
  def [] pos
    row, col = pos
    @rows[row][col]
  end
  
  def out_of_bounds(pos)
    !within_bounds(pos)
  end
  
  def within_bounds(pos)
    row, col = pos
    (0...height).include?(row) && (0...width).include?(col)
  end
  
  def flag(row, col)
    @rows[row][col].state = :flagged
  end
  
  def reveal(row, col)
    tile = @rows[row][col]
    if tile.bomb
      @revealed_bomb = true
    else
      if tile.state != :revealed
        tile.state = :revealed
        if tile.neighbor_bomb_count == 0
          tile.neighbors.each do |neighbor|
            reveal(neighbor.row, neighbor.col)
          end
        end
      end
    end
  end
  
  def game_over?
    game_won? || game_lost?
  end
  
  def game_won?
    !game_lost? && (@rows.flatten.all? do |tile|
      tile.state == :revealed || tile.bomb
    end)
  end
  
  def game_lost?
    @revealed_bomb
  end
end

class Game
  attr_accessor :board, :move_type, :row, :col
  
  def initialize
    @board = Board.new
  end
  
  def game_over?
    @board.game_over?
  end

  def reveal
    # puts "Revealing position #{@row}, #{@col}"
    @board.reveal(@row, @col)
  end
  
  def flag
    # puts "Flagging position #{@row}, #{@col}"
    @board.flag(@row, @col)
  end
  
  def update_board
    case @move_type
    when 'r'
      reveal
    when 'f'
      flag
    end
  end
end

class UserInterface
  def initialize(save_filename = nil)
    if save_filename.nil?
      new_game
    else
      load_game(save_filename)
    end
  end
  
  def play
    welcome_message
    until @game.game_over?
      display_board
      take_input
      @game.update_board
    end
    if @game.board.game_won?
      display_victory_message
    else
      display_defeat_message
    end
  end
  
  def new_game
    @game = Game.new
  end
  
  def load_game(filename)
    @game = YAML.load(File.readlines(filename).join("\n"))
  end
  
  def save_game(filename)
    file = File.open(filename, 'w')
    file.puts @game.to_yaml
    file.close
  end
end

class ConsoleUserInterface < UserInterface
  def welcome_message
    puts "WELCOME TO MINESWEEPER"
  end
  
  def display_victory_message
    puts "VICTORY"
  end
  
  def display_defeat_message
    puts "DEFEAT"
  end
  
  def display_board
    puts((0...@game.board.height).map do |row|
      (0...@game.board.width).map do |col|
        tile_to_character @game.board[ [row, col] ]
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
    @game.move_type, *args = gets.split
    
    unless ['r','f','s','l'].include?(@game.move_type)
      puts "Invalid move type. Move type must be 'r', 'f', 's', 'l'"
      return take_input
    end
    
    return save_game(args[0]) if @game.move_type == 's'
    return load_game(args[0]) if @game.move_type == 'l'
    
    row, col = args
    
    unless row =~ /^\d+$/ && col =~ /^\d+$/
      puts "Invalid row and/or column"
      puts "Row and column must be integers"
      return take_input
    end
    
    @game.row, @game.col = [row, col].map(&:to_i)
    
    unless @game.row < @game.board.height
      puts "row must be between 0 and #{@board.height-1}"
      return take_input
    end
    
    unless @game.col < @game.board.width
      puts "column must be between 0 and #{@board.width-1}"
      return take_input
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  game = ConsoleUserInterface.new
  game.play
end

