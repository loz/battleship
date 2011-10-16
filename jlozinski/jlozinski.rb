class JLozinskiPlayer

  attr_reader :last_shot, :state, :rand

  def initialize
    @rand = Random.new
  end

  def name
    "Jonathan Lozinski"
  end

  def new_game
    @targets = []
    [
      [3, 0, 5, :across],
      [0, 2, 4, :down],
      [6, 5, 3, :across],
      [2, 6, 3, :down],
      [8, 8, 2, :across]
    ]
  end

  def take_turn(state, ships_remaining)
    @state = state
    if last_shot_hit?
      @targets += targets_around_last_shot
    end
    @last_shot = get_shot
  end

  def get_shot
    unless @targets.empty?
      @targets.pop
    else
      get_random_shot
    end

  end

  def get_random_shot
    x,y = rand.rand(10), rand.rand(10)
    [x,y]
  end

  def last_shot_hit?
    return false unless last_shot
    x, y = last_shot
    state[y][x] == :hit
  end

  def targets_around_last_shot
    x, y = last_shot
    targets = []
    targets << [x-1, y] unless x==0 || state[y][x-1] != :unknown
    targets << [x+1, y] unless x==9 || state[y][x+1] != :unknown
    targets << [x, y-1] unless y==0 || state[y-1][x] != :unknown
    targets << [x, y+1] unless y==9 || state[y+1][x] != :unknown
    targets
  end

end
