# frozen_string_literal: true

class Game < ApplicationRecord
  belongs_to :player_1, class_name: 'Player', foreign_key: 'player_1_id'
  belongs_to :player_2, class_name: 'Player', foreign_key: 'player_2_id'
  belongs_to :turn, class_name: 'Player', foreign_key: 'turn_id'
  belongs_to :winner, class_name: 'Player', foreign_key: 'winner_id', optional: true

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

  def calculate_scores_cancel
    if winner == player_1
      player_1.wins   += 1
      player_2.losses += 1
      player_1.rating += 1
      player_2.rating -= 1
    elsif winner == player_2
      player_2.wins   += 1
      player_1.losses += 1
      player_2.rating += 1
      player_1.rating -= 1
    end
    player_1.save!
    player_2.save!
  end

  def calculate_scores
    p1 = player_1.rating
    p2 = player_2.rating
    p1_p2 = p1 + p2
    p1_r = p1.to_f / p1_p2
    p2_r = p2.to_f / p1_p2
    p1_p = (32 * p1_r).to_i
    p2_p = (32 * p2_r).to_i
    if winner == player_1
      player_1.wins   += 1
      player_2.losses += 1
      player_1.rating += p2_p
      player_2.rating -= p2_p
    elsif winner == player_2
      player_2.wins   += 1
      player_1.losses += 1
      player_2.rating += p1_p
      player_1.rating -= p1_p
    end
    player_1.save!
    player_2.save!
  end

  def attack_sinking_ship(player, opponent)
    layout = get_sinking_ship(opponent)
    if layout
      move = if layout.moves.count == 1
               attack_1(player, opponent, layout.moves.first)
             else
               attack_2(player, opponent, layout.moves)
             end
      return move
    end
    nil
  end

  def get_random_move_lines(player)
    cols = Array.new(10, 0)
    rows = Array.new(10, 0)
    10.times do |i|
      cols[i] = moves.for_player(player).where(layout: nil, x: i).count
      rows[i] = moves.for_player(player).where(layout: nil, y: i).count
    end
    min_cols = []
    min_rows = []
    10.times do |i|
      min_cols << i if cols[i] == cols.min
      min_rows << i if rows[i] == rows.min
    end
    x = min_cols.sample
    y = min_rows.sample
    move = moves.for_player(player).where(x: x, y: y).first
    return get_totally_random_move(player) if move

    [x, y]
  end

  def get_random_move_spacing(player)
    mvs = moves.for_player(player)
    grid = Array.new(10, Array.new(10, ''))
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
    possibles = []
    10.times do |x|
      10.times do |y|
        next if grid[x][y].size == 1

        count = 0
        ((x - 1)..(x + 1)).each do |c|
          next if c.negative? || c > 9

          ((y - 1)..(y + 1)).each do |r|
            next if r.negative? || r > 9

            next if x == c && y == r

            count += 1 if grid[c][r].empty?
          end
        end
        possibles << [[x, y], count] if count.positive?
      end
    end
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

  def get_totally_random_move(player)
    x = (0..9).to_a.sample
    y = (0..9).to_a.sample
    move = moves.for_player(player).where(x: x, y: y).first
    return [x, y] unless move

    get_totally_random_move(player)
  end

  def again?(player)
    r = (1..100).to_a.sample
    return true if player.id == 1 && r < 96
    return true if player.id == 2 && r < 97
    return true if player.id == 3 && r < 98
    return true if player.id == 4 && r < 99

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
        layout = hit?(opponent, x, y)
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
      return layout if moves.for_layout(layout).count > 0
    end
    nil
  end

  def empty_neighbors(player, hit)
    cols = []
    rows = []
    [[-1, 0], [1, 0], [0, -1], [0, 1]].each do |cr|
      next unless (hit.x + cr[0]).between?(0, 9) &&
                  (hit.y + cr[1]).between?(0, 9) &&
                  moves.for_player(player).for_xy(hit.x + cr[0], hit.y + cr[1]).empty?

      cols << hit.x + cr[0]
      rows << hit.y + cr[1]
    end
    [cols, rows]
  end

  def attack_1(player, opponent, hit)
    cols, rows = empty_neighbors(player, hit)
    unless cols.empty?
      r = (0..(cols.size - 1)).to_a.sample
      layout = hit?(opponent, cols[r], rows[r])
      move = moves.create!(player: player, layout: layout, x: cols[r], y: rows[r])
      return true if move.persisted?
    end
    false
  end

  def attack_2(player, opponent, hits)
    cols = []
    rows = []
    vertical = hits[0].x == hits[1].x
    hit_cols = hits.collect(&:x)
    hit_rows = hits.collect(&:y)
    if vertical
      min_hit_rows = hit_rows.min - 1
      min_hit_rows = min_hit_rows < 0 ? 0 : min_hit_rows
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
      min_hit_cols = min_hit_cols < 0 ? 0 : min_hit_cols
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
end
