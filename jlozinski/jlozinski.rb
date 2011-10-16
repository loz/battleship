class JLozinskiPlayer

  attr_reader :last_shot, :state, :rand, :ships_to_find

  def initialize
    @rand = Random.new
    @string_maps = {
      :unknown => 'U',
      :miss => 'M',
      :hit => 'H'
    }
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
    @ships_to_find = ships_remaining
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

  def stringify_row(row)
    row.map {|c| @string_maps[c]}.join
  end

  def possible_locations_in_row(row, ship)
    row_str = stringify_row(row)
    target = 'U' * ship
    locations = []
    while loc = row_str.index(target) do
      locations << loc
      row_str[loc] = 'X'
    end
    locations
  end

  def possible_locations_for_ship(ship)
    possible = []
    state.each_index do |y|
      row = state[y]
      possible += (possible_locations_in_row(row, ship)).map {|x| [x,y]}
    end
    possible
  end

  def possible_shots_for_ship(ship)
    shots = []
    possible_locations_for_ship(ship).each do |location|
      shots += parts_for_ship(ship, *location, :across)
    end
    shots
  end

  def parts_for_ship(ship, x, y, orientation)
    case orientation
      when :across
        (0...ship).map { |s| [x+s, y] }
      when :down
        (0...ship).map { |s| [x, y+s] }
    end
  end

  def get_random_shot
    possible_locations_for_ship(ships_to_find.max).sample(1).first
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
