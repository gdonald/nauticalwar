# frozen_string_literal: true

class Game < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :player1, class_name: 'Player'
  belongs_to :player2, class_name: 'Player'
  belongs_to :turn, class_name: 'Player'
  belongs_to :winner,
             class_name: 'Player',
             optional: true

  has_many :layouts, dependent: :destroy
  has_many :moves, dependent: :destroy

  validates :time_limit, presence: true

  validates :rated,      inclusion: [true, false]
  validates :shots_per_turn, inclusion: 1..5
  validates :del_player1, inclusion: [true, false]
  validates :del_player2, inclusion: [true, false]

  validates :player1_layed_out, inclusion: [true, false]
  validates :player2_layed_out, inclusion: [true, false]

  scope :ordered, -> { order(created_at: :asc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at del_player1 del_player2 id id_value player1_id player1_layed_out player2_id player2_layed_out rated
       shots_per_turn time_limit turn_id updated_at winner_id]
  end

  def self.create_ships
    Ship.create!(name: 'Carrier',     size: 5)
    Ship.create!(name: 'Battleship',  size: 4)
    Ship.create!(name: 'Destroyer',   size: 3)
    Ship.create!(name: 'Submarine',   size: 3)
    Ship.create!(name: 'Patrol Boat', size: 2)
  end

  def self.find_game(player, id)
    game = find_by(id:)
    game && [game.player1, game.player2].include?(player) ? game : nil
  end

  def rand_n(low, high)
    (low..high).to_a.sample
  end

  def rand_col_row(col_max, row_max)
    [rand_n(0, col_max), rand_n(0, row_max)]
  end

  def in_grid?(pos)
    pos.between?(0, 9)
  end

  def normal_range(min, max)
    ((min.negative? ? 0 : min)..([max, 9].min))
  end

  def vertical_location(player, ship)
    c, r = rand_col_row(9, 10 - ship.size)
    (r...(r + ship.size)).each do |y|
      return vertical_location(player, ship) if hit?(player, c, y).present?
    end
    [c, r]
  end

  def horizontal_location(player, ship)
    c, r = rand_col_row(10 - ship.size, 9)
    (c...(c + ship.size)).each do |x|
      return horizontal_location(player, ship) if hit?(player, x, r).present?
    end
    [c, r]
  end

  def t_limit
    (updated_at + time_limit.seconds - Time.current).seconds.to_i
  end

  def moves_for_player(player)
    moves.where(player:)
  end

  def layouts_for_player(player)
    layouts.where(player:).ordered
  end

  def layouts_for_opponent(opponent)
    layouts.where(player: opponent, sunk: true).ordered
  end

  def move_exists?(player, col, row)
    moves_for_player(player).where(x: col, y: row).first.present?
  end

  def hit?(player, col, row)
    reload
    layouts.for_player(player).each do |layout|
      return layout if layout.hit?(col, row)
    end
    nil # rubocop:disable Style/ReturnNilInPredicateMethodDefinition
  end

  def create_ship_layout(player, hash)
    ship = Ship.find_by(name: hash['name'])
    return unless ship

    layouts.create!(player:, ship:, x: hash['x'], y: hash['y'],
                    vertical: hash['vertical'] == '1')
  end

  # TODO: validate layout for overlap and out of bounds
  def create_ship_layouts(player, json)
    ships = parse_ships(json)
    ships.each { |s| create_ship_layout(player, s) }
    player = player == player1 ? 1 : 2
    update("player#{player}_layed_out": true)
  end

  def parse_ships(json)
    JSON.parse(json)['ships']
  end

  def parse_shots(json)
    JSON.parse(json).slice(0, shots_per_turn)
  end

  def bot_attack_5! # rubocop:disable Metrics/AbcSize
    player2.strength.times do
      move = attack_sinking_ship(player2, player1)
      attack_random_ship(player2, player1) if move.nil?
    end
    (5 - player2.strength).times do
      attack_random_ship(player2, player1)
    end
  end

  def bot_attack_4! # rubocop:disable Metrics/AbcSize
    strength = player2.strength - 1
    strength = 0 if strength.negative?
    strength.times do
      move = attack_sinking_ship(player2, player1)
      attack_random_ship(player2, player1) if move.nil?
    end
    (4 - strength).times do
      attack_random_ship(player2, player1)
    end
  end

  def bot_attack_3! # rubocop:disable Metrics/AbcSize
    strength = player2.strength - 1
    strength = 0 if strength.negative?
    strength.times do
      move = attack_sinking_ship(player2, player1)
      attack_random_ship(player2, player1) if move.nil?
    end
    (3 - strength).times do
      attack_random_ship(player2, player1)
    end
  end

  def bot_attack_2! # rubocop:disable Metrics/AbcSize
    strength = player2.strength - 1
    strength = 0 if strength.negative?
    strength.times do
      move = attack_sinking_ship(player2, player1)
      attack_random_ship(player2, player1) if move.nil?
    end
    (2 - strength).times do
      attack_random_ship(player2, player1)
    end
  end

  def bot_attack_1!
    move = attack_sinking_ship(player2, player1)
    attack_random_ship(player2, player1) if move.nil?
  end

  def bot_attack!
    player2.new_activity!
    send("bot_attack_#{shots_per_turn}!")
    next_turn! if winner.nil?
  end

  def bot_layout
    Ship.ordered.each do |ship|
      Layout.set_location(self, player2, ship, [0, 1].sample.zero?)
    end
    update(player2_layed_out: true)
  end

  def guest_layout
    Ship.ordered.each do |ship|
      Layout.set_location(self, player1, ship, [0, 1].sample.zero?)
    end
    update(player1_layed_out: true)
  end

  def player(player)
    player == player1 ? player1 : player2
  end

  def opponent(player)
    player == player1 ? player2 : player1
  end

  def all_ships_sunk?(player)
    layouts.unsunk_for_player(player).empty?
  end

  def make_winner!(player)
    update(winner: player)
  end

  def declare_winner
    [player1, player2].each do |player|
      make_winner!(player) if all_ships_sunk?(opponent(player))
    end
  end

  def next_player_turn
    turn == player1 ? player2 : player1
  end

  def can_attack?(player)
    winner.nil? && turn == player
  end

  def next_turn!
    update(turn: next_player_turn)
    layouts.unsunk.each(&:sunk?)
    declare_winner
    calculate_scores if rated && winner.present?
    touch # rubocop:disable Rails/SkipsModelValidations
  end

  def update_winner(player, variance)
    player.wins   += 1
    player.rating += variance
    player.save!
  end

  def update_loser(player, variance)
    player.losses += 1
    player.rating -= variance
    player.save!
  end

  def score_variance(player1, player2)
    p1 = player1.rating
    p2 = player2.rating
    p12 = p1 + p2
    [(32 * p1.to_f / p12).to_i, (32 * p2.to_f / p12).to_i]
  end

  def calculate_scores(cancel: false)
    p1_p, p2_p = cancel ? [1, 1] : score_variance(player1, player2)
    if winner == player1
      update_winner(player1, p2_p)
      update_loser(player2, p2_p)
    elsif winner == player2
      update_winner(player2, p1_p)
      update_loser(player1, p1_p)
    end
  end

  def col_row_moves(player)
    cols = Array.new(10, 0)
    rows = Array.new(10, 0)
    mvs = moves.for_player(player).for_layout(nil)
    10.times do |i|
      cols[i] = mvs.where(x: i).count
      rows[i] = mvs.where(y: i).count
    end
    [cols, rows]
  end

  def random_min_col_row(cols, rows)
    min_cols = []
    min_rows = []
    10.times do |i|
      min_cols << i if cols[i] == cols.min
      min_rows << i if rows[i] == rows.min
    end
    [min_cols.sample, min_rows.sample]
  end

  def get_random_move_lines(player)
    cols, rows = col_row_moves(player)
    x, y = random_min_col_row(cols, rows)
    move = moves.for_player(player).where(x:, y:).first
    return get_totally_random_move(player) if move

    [x, y]
  end

  def hit_miss_grid(player)
    mvs = moves.for_player(player)
    grid = Array.new(10) { Array.new(10, '') }
    10.times do |x|
      10.times do |y|
        hit = ''
        mvs.each do |m|
          if m.x == x && m.y == y
            hit = m.layout ? 'H' : 'M'
            break
          end
        end
        grid[x][y] = hit
      end
    end
    grid
  end

  def spacing_moves_count(x_pos, y_pos, grid) # rubocop:disable Metrics/CyclomaticComplexity
    count = 0
    ((x_pos - 1)..(x_pos + 1)).each do |c|
      next unless in_grid?(c)

      ((y_pos - 1)..(y_pos + 1)).each do |r|
        next if (x_pos == c && y_pos == r) || !in_grid?(r)

        count += 1 if grid[c][r].empty?
      end
    end
    count
  end

  def get_possible_spacing_moves(player)
    grid = hit_miss_grid(player)
    possibles = []
    10.times do |x|
      10.times do |y|
        next if grid[x][y].size == 1

        count = spacing_moves_count(x, y, grid)
        possibles << [[x, y], count] if count.positive?
      end
    end
    possibles
  end

  def get_random_move_spacing(player)
    possibles = get_possible_spacing_moves(player)
    return get_totally_random_move(player) if possibles.blank?

    possibles.sort_by! { |p| p[1] }.reverse
    high = possibles[0][1]
    best = []
    possibles.each do |p|
      best << p if p[1] == high
    end
    best.sample[0]
  end

  def get_totally_random_move(player)
    x, y = rand_col_row(9, 9)
    move = moves.for_player(player).where(x:, y:).first
    return [x, y] unless move

    get_totally_random_move(player)
  end

  def again?(player)
    r = rand_n(1, 100)
    [[1, 96], [2, 97], [3, 98], [4, 99]].each do |a|
      return true if player.id == a[0] && r < a[1]
    end
    false
  end

  def attack_random_ship(player, opponent) # rubocop:disable Metrics
    x, y = get_random_move_lines(player)
    layout = hit?(opponent, x, y)
    if layout.nil? && again?(player)
      x, y = get_random_move_spacing(player)
      layout = hit?(opponent, x, y)
      x, y = get_random_move_lines(player) if layout.nil? && again?(player)
    end
    move = moves.for_player(player).for_xy(x, y).first
    x, y = get_totally_random_move(player) if move
    layout = hit?(opponent, x, y)
    move = moves.create!(player:, layout:, x:, y:)
    move.persisted?
  end

  def get_sinking_ship(player)
    layouts.unsunk_for_player(player).each do |layout|
      return layout if moves.for_layout(layout).count.positive?
    end
    nil
  end

  def empty_neighbor?(player, x_pos, y_pos)
    x_pos.between?(0, 9) && y_pos.between?(0, 9) &&
      moves.for_player(player).for_xy(x_pos, y_pos).empty?
  end

  def empty_neighbors(player, hit)
    cols = []
    rows = []
    [[-1, 0], [1, 0], [0, -1], [0, 1]].each do |col, row|
      x = hit.x + col
      y = hit.y + row
      next unless empty_neighbor?(player, x, y)

      cols << x
      rows << y
    end
    [cols, rows]
  end

  # rubocop:disable /AbcSize, Metrics/
  def attack_unknown_vert(player, opponent, hit)
    cols, rows = empty_neighbors(player, hit)
    unless cols.empty?
      r = (0..(cols.size - 1)).to_a.sample
      layout = hit?(opponent, cols[r], rows[r])
      args = { player:, layout:, x: cols[r], y: rows[r] }
      move = moves.create!(args)
      return true if move.persisted?
    end
    false
  end

  def attack_vertical(player, hits) # rubocop:disable Metrics/AbcSize
    cols_rows = [[], []]
    hit_rows = hits.collect(&:y)
    normal_range(hit_rows.min - 1, hit_rows.max + 1).each do |r|
      move = moves.for_player(player).where(x: hits[0].x, y: r).ordered.first
      next if move

      cols_rows[0] << hits[0].x
      cols_rows[1] << r
    end
    cols_rows
  end

  def attack_horizontal(player, hits) # rubocop:disable Metrics/AbcSize
    cols_rows = [[], []]
    hit_cols = hits.collect(&:x)
    normal_range(hit_cols.min - 1, hit_cols.max + 1).each do |c|
      move = moves.for_player(player).where(x: c, y: hits[0].y).ordered.first
      next if move

      cols_rows[0] << c
      cols_rows[1] << hits[0].y
    end
    cols_rows
  end

  def create_known_vert_move(cols, rows, player, opponent)
    r = rand_n(0, cols.size - 1)
    layout = hit?(opponent, cols[r], rows[r])
    moves.create!(player:, layout:, x: cols[r], y: rows[r])
  end

  def attack_known_vert(player, opponent, hits)
    if hits[0].x == hits[1].x
      cols, rows = attack_vertical(player, hits)
    else
      cols, rows = attack_horizontal(player, hits)
    end
    create_known_vert_move(cols, rows, player, opponent) if cols.any?
  end

  def attack_sinking_ship(player, opponent)
    layout = get_sinking_ship(opponent)
    return nil unless layout

    if layout.moves.count == 1
      attack_unknown_vert(player, opponent, layout.moves.first)
    else
      attack_known_vert(player, opponent, layout.moves)
    end
  end
end
