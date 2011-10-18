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
    #Seed targets with weak parts of weight algorithm
    @targets << [3,0]
    @targets << [6,0]
    @targets << [3,0]
    @targets << [6,9]
    @targets << [0,3]
    @targets << [0,6]
    @targets << [9,3]
    @targets << [9,6]
    @hits_in_target = 0
    @ships_to_find = [5,4,3,3,2]
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
      @hits_in_target += 1
      sunk = ship_hit(ships_remaining)
      if sunk && sunk == @hits_in_target
        #stop searching around that area
        @targets = []
        @hits_in_target = 0
      else
        @hits_in_target -= sunk if sunk
        @targets += targets_around_last_shot
        @targets.uniq!
      end
    end
    @ships_to_find = ships_remaining
    @last_shot = get_shot
  end

  def ship_hit(remaining)
    a = @ships_to_find.sort.reverse
    b = remaining.sort.reverse
    kill = nil
    while x = a.pop do
      y = b.pop
      if x != y
        kill = x
        break
      end
    end
    kill
  end

  def get_shot
    unless @targets.empty?
      @targets.pop
    else
      get_likely_shot 
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

  def possible_locations_for_ship(ship, direction=:across)
    possible = []
    case direction
      when :across
        state.each_index do |y|
          row = state[y]
          possible += (possible_locations_in_row(row, ship)).map {|x| [x,y]}
        end
      when :down
        #translate x and y coords
        tstate = state.transpose
        tstate.each_index do |x|
          row = tstate[x]
          possible += (possible_locations_in_row(row, ship)).map {|y| [x,y]}
        end
    end
    possible
  end

  def possible_shots_for_ship(ship)
    shots = []
    #horizontals
    possible_locations_for_ship(ship).each do |location|
      shots += parts_for_ship(ship, *location, :across)
    end
    #verticals
    possible_locations_for_ship(ship, :down).each do |location|
      shots += parts_for_ship(ship, *location, :down)
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

  def get_likely_shot
    #Heatmap from ALL remaining ships
    #possible = []
    #ships_to_find.each do |s|
    #  possible += possible_shots_for_ship(s)
    #end

    #Heatmap from LARGEST remaining ship
    possible = possible_shots_for_ship(ships_to_find.max)
    
    #Random possible rather than heatmap
    #return possible.sample(1).first
    
    heatmap = build_heatmap(possible)
    find_hottest(heatmap).sample(1).first
  end

  def find_hottest(m)
    hottest = []
    heat = 0
    m.each_index do |y|
      m[y].each_index do |x|
        h = m[y][x]
        if h == heat
          hottest << [x,y]
        elsif h > heat
          heat = h
          hottest = [[x,y]]
        end
      end
    end
    hottest
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

  def build_heatmap(targets)
    m = Array.new(10) do
      Array.new(10, 0)
    end
    
    targets.each do |x,y|
      m[y][x]+= 1
    end
    m
  end

  def print_heatmap(m)
    puts
    m.each do |y|
      y.each do |x|
        print "%02d " % x
      end
      puts
    end
  end

  def do_heatmap(targets)
    m = build_heatmap(targets)
    print_heatmap(m)
    print_heatmap(m)
  end

end
