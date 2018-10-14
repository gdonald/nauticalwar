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

  def is_hit?(player, col, row)
    reload
    layouts.for_player(player).each do |layout|
      return layout if layout.is_hit?(col, row)
    end
    nil
  end

  def bot_layout
    Ship.ordered.each do |ship|
      Layout.set_location(game: self, player: player_2, ship: ship)
    end
    update_attributes(player_2_layed_out: true)
  end

  def opponent(player)
    player == player_1 ? player_2 : player_1
  end

  def next_turn
    new_turn = turn == player_1 ? player_2 : player_1
    update_attributes(turn: new_turn)
    layouts.unsunk.each(&:check_sunk)
    update_attributes(winner: player_2) if layouts.sunk_for_player(player_1).count == 5
    update_attributes(winner: player_1) if layouts.sunk_for_player(player_2).count == 5
    calculate_scores unless winner.nil?
    touch
  end

  def calculate_scores_cancel
    return unless rated && winner
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
    return unless rated && winner
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
    log('attack_sinking_ship()')
    layout = get_sinking_ship(opponent)
    if layout
      move = if layout.moves.count == 1
               attack_1(player, opponent, layout.moves.first)
             else
               attack_2(player, opponent, layout.moves)
             end
      log("  returning move: #{move}")
      return move
    end
    log('  returning nil')
    nil
  end

  def get_random_move_lines(player)
    log('get_random_move_lines()')
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
    log("  move: #{move}")
    return get_totally_random_move(player) if move
    log("  returning with x: #{x}, y: #{y}")
    [x, y]
  end

  def get_random_move_spacing(player)
    log('get_random_move_spacing()')
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
          next if c < 0 || c > 9
          ((y - 1)..(y + 1)).each do |r|
            next if r < 0 || r > 9
            next if x == c && y == r
            count += 1 if grid[c][r].empty?
          end
        end
        possibles << [[x, y], count] if count > 0
      end
    end
    if possibles.any?
      possibles.sort_by! { |p| p[1] }.reverse
      high = possibles[0][1]
      best = []
      possibles.each do |p|
        best << p if p[1] == high
      end
      log("  returning with best sample: #{best.sample[0]}")
      return best.sample[0]
    end
    get_totally_random_move(player)
  end

  def get_totally_random_move(player)
    log('get_totally_random_move()')
    x = (0..9).to_a.sample
    y = (0..9).to_a.sample
    move = moves.for_player(player).where(x: x, y: y).first
    log("  move: #{move}")
    log("  x: #{x}, y: #{y}")
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
    log('attack_random_ship()')

    x, y = get_random_move_lines(player)
    layout = is_hit?(opponent, x, y)

    if layout.nil? && again?(player)
      x, y = get_random_move_spacing(player)
      layout = is_hit?(opponent, x, y)

      if layout.nil? && again?(player)
        x, y = get_random_move_lines(player)
        layout = is_hit?(opponent, x, y)
      end
    end

    move = moves.for_player(player).for_xy(x, y).first
    log("  move exists?: #{move}")
    x, y = get_totally_random_move(player) if move
    log("x: #{x} y: #{y}")

    layout = is_hit?(opponent, x, y)
    move = moves.create!(player: player, layout: layout, x: x, y: y)
    log("  move create!: #{move}")
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
      next unless (hit.x + cr[0]).between?(0, 9) && (hit.y + cr[1]).between?(0, 9)
      next unless moves.for_player(player).for_xy(hit.x + cr[0], hit.y + cr[1]).empty?
      cols << hit.x + cr[0]
      rows << hit.y + cr[1]
    end
    [cols, rows]
  end

  def attack_1(player, opponent, hit)
    cols, rows = empty_neighbors(player, hit)
    unless cols.empty?
      r = (0..(cols.size - 1)).to_a.sample
      layout = is_hit?(opponent, cols[r], rows[r])
      move = moves.create!(player: player, layout: layout, x: cols[r], y: rows[r])
      return true if move.persisted?
    end
    false
  end

  def attack_2(player, opponent, hits)
    log('attack_2()')
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

    log("  cols: #{cols}")
    return false if cols.empty?

    r = (0..(cols.size - 1)).to_a.sample
    layout = is_hit?(opponent, cols[r], rows[r])
    move = moves.create!(player: player, layout: layout, x: cols[r], y: rows[r])
    log("  move: #{move}")

    return move if move.persisted?

    log('  returning false')
    false
  end
end
