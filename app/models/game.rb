# frozen_string_literal: true

class Game < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :player_1, class_name: 'Player', foreign_key: 'player_1_id'
  belongs_to :player_2, class_name: 'Player', foreign_key: 'player_2_id'
  belongs_to :turn, class_name: 'Player', foreign_key: 'turn_id'
  belongs_to :winner,
             class_name: 'Player',
             foreign_key: 'winner_id',
             optional: true

  has_many :layouts
  has_many :moves

  validates :time_limit, presence: true

  validates :rated,      inclusion: [true, false]
  validates :five_shot,  inclusion: [true, false]
  validates :del_player_1, inclusion: [true, false]
  validates :del_player_2, inclusion: [true, false]

  validates :player_1_layed_out, inclusion: [true, false]
  validates :player_2_layed_out, inclusion: [true, false]

  scope :ordered, -> { order(created_at: :asc) }

  def self.create_ships
    Ship.create!(name: 'Patrol Boat', size: 2)
    Ship.create!(name: 'Destroyer',   size: 3)
    Ship.create!(name: 'Submarine',   size: 3)
    Ship.create!(name: 'Battleship',  size: 4)
    Ship.create!(name: 'Carrier',     size: 5)
  end

  def self.find_game(player, id)
    game = find_by(id: id)
    game && [game.player_1, game.player_2].include?(player) ? game : nil
  end

  def t_limit
    (updated_at + time_limit.seconds - Time.current).seconds.to_i
  end

  def moves_for_player(player)
    moves.where(player: player)
  end

  def hit?(player, col, row)
    reload
    layouts.for_player(player).each do |layout|
      return layout if layout.hit?(col, row)
    end
    nil
  end

  def bot_layout
    Ship.ordered.each do |ship|
      Layout.set_location(self, player_2, ship, [0, 1].sample.zero?)
    end
    update_attributes(player_2_layed_out: true)
  end

  def opponent(player)
    player == player_1 ? player_2 : player_1
  end

  def next_player_turn
    turn == player_1 ? player_2 : player_1
  end

  def all_ships_sunk?(player)
    layouts.unsunk_for_player(player).empty?
  end

  def declare_winner
    [player_1, player_2].each do |player|
      update_attributes(winner: player) if all_ships_sunk?(opponent(player))
    end
  end

  def next_turn
    update_attributes(turn: next_player_turn)
    layouts.unsunk.each(&:sunk?)
    declare_winner
    calculate_scores if rated && winner.present?
    touch
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

  def score_variance(player_1, player_2)
    p1 = player_1.rating
    p2 = player_2.rating
    p12 = p1 + p2
    [(32 * p1.to_f / p12).to_i, (32 * p2.to_f / p12).to_i]
  end

  def calculate_scores(cancel = false)
    p1_p, p2_p = cancel ? [1, 1] : score_variance(player_1, player_2)
    if winner == player_1
      update_winner(player_1, p2_p)
      update_loser(player_2, p2_p)
    elsif winner == player_2
      update_winner(player_2, p1_p)
      update_loser(player_1, p1_p)
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
    move = moves.for_player(player).where(x: x, y: y).first
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

  def in_grid?(n)
    n.between?(0, 9)
  end

  def get_possible_spacing_moves(player)
    grid = hit_miss_grid(player)
    possibles = []
    10.times do |x|
      10.times do |y|
        next if grid[x][y].size == 1

        count = 0
        ((x - 1)..(x + 1)).each do |c|
          next unless in_grid?(c)

          ((y - 1)..(y + 1)).each do |r|
            next unless in_grid?(r)
            next if x == c && y == r

            count += 1 if grid[c][r].empty?
          end
        end
        possibles << [[x, y], count] if count.positive?
      end
    end
    possibles
  end

  def get_random_move_spacing(player)
    possibles = get_possible_spacing_moves(player)
    if possibles.any?
      possibles.sort_by! { |p| p[1] }.reverse
      high = possibles[0][1]
      best = []
      possibles.each do |p|
        best << p if p[1] == high
      end
      return best.sample[0]
    end
    get_totally_random_move(player)
  end

  def self.rand_xy
    a = (0..9).to_a
    [a.sample, a.sample]
  end

  def get_totally_random_move(player)
    x, y = Game.rand_xy
    move = moves.for_player(player).where(x: x, y: y).first
    return [x, y] unless move

    get_totally_random_move(player)
  end

  def again?(player)
    r = (1..100).to_a.sample
    [[1, 96], [2, 97], [3, 98], [4, 99]].each do |a|
      return true if player.id == a[0] && r < a[1]
    end
    false
  end

  def attack_random_ship(player, opponent)
    x, y = get_random_move_lines(player)
    layout = hit?(opponent, x, y)
    if layout.nil? && again?(player)
      x, y = get_random_move_spacing(player)
      layout = hit?(opponent, x, y)
      if layout.nil? && again?(player)
        x, y = get_random_move_lines(player)
      end
    end
    move = moves.for_player(player).for_xy(x, y).first
    x, y = get_totally_random_move(player) if move
    layout = hit?(opponent, x, y)
    move = moves.create!(player: player, layout: layout, x: x, y: y)
    move.persisted?
  end

  def get_sinking_ship(player)
    layouts.unsunk_for_player(player).each do |layout|
      return layout if moves.for_layout(layout).count.positive?
    end
    nil
  end

  def empty_neighbor?(player, x, y)
    x.between?(0, 9) && y.between?(0, 9) &&
      moves.for_player(player).for_xy(x, y).empty?
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

  def attack_1(player, opponent, hit) # rubocop:disable Metrics/AbcSize
    cols, rows = empty_neighbors(player, hit)
    unless cols.empty?
      r = (0..(cols.size - 1)).to_a.sample
      layout = hit?(opponent, cols[r], rows[r])
      args = { player: player, layout: layout, x: cols[r], y: rows[r] }
      move = moves.create!(args)
      return true if move.persisted?
    end
    false
  end

  def attack_2(player, opponent, hits) # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/LineLength
    cols = []
    rows = []
    vertical = hits[0].x == hits[1].x
    hit_cols = hits.collect(&:x)
    hit_rows = hits.collect(&:y)
    if vertical
      min_hit_rows = hit_rows.min - 1
      min_hit_rows = min_hit_rows.negative? ? 0 : min_hit_rows
      max_hit_rows = hit_rows.max + 1
      max_hit_rows = max_hit_rows > 9 ? 9 : max_hit_rows
      (min_hit_rows..max_hit_rows).each do |r|
        move = moves.for_player(player).where(x: hits[0].x, y: r).ordered.first
        if move.nil?
          cols << hits[0].x
          rows << r
        end
      end
    else
      min_hit_cols = hit_cols.min - 1
      min_hit_cols = min_hit_cols.negative? ? 0 : min_hit_cols
      max_hit_cols = hit_cols.max + 1
      max_hit_cols = max_hit_cols > 9 ? 9 : max_hit_cols
      (min_hit_cols..max_hit_cols).each do |c|
        move = moves.for_player(player).where(x: c, y: hits[0].y).ordered.first
        if move.nil?
          cols << c
          rows << hits[0].y
        end
      end
    end
    return false if cols.empty?

    r = (0..(cols.size - 1)).to_a.sample
    layout = hit?(opponent, cols[r], rows[r])
    move = moves.create!(player: player, layout: layout, x: cols[r], y: rows[r])
    return move if move.persisted?

    false
  end

  def attack_sinking_ship(player, opponent)
    layout = get_sinking_ship(opponent)
    return nil unless layout
    if layout.moves.count == 1
      attack_1(player, opponent, layout.moves.first)
    else
      attack_2(player, opponent, layout.moves)
    end
  end
end
