# frozen_string_literal: true

class Game < ApplicationRecord
  belongs_to :user_1, class_name: 'User', foreign_key: 'user_1_id'
  belongs_to :user_2, class_name: 'User', foreign_key: 'user_2_id'
  belongs_to :turn,   class_name: 'User', foreign_key: 'turn_id'
  belongs_to :winner, class_name: 'User', foreign_key: 'winner_id', optional: true

  has_many :layouts
  has_many :moves

  validates :time_limit, presence: true

  validates :rated,      inclusion: [true, false]
  validates :five_shot,  inclusion: [true, false]
  validates :del_user_1, inclusion: [true, false]
  validates :del_user_2, inclusion: [true, false]

  validates :user_1_layed_out, inclusion: [true, false]
  validates :user_2_layed_out, inclusion: [true, false]

  scope :ordered, -> { order(created_at: :asc) }

  def self.find_game(user, id)
    game = find_by(id: id)
    game && [game.user_1, game.user_2].include?(user) ? game : nil
  end

  def t_limit
    (updated_at + time_limit.seconds - Time.current).seconds.to_i
  end

  def moves_for_user(user)
    moves.where(user: user)
  end

  def is_hit?(user, col, row)
    reload
    layouts.for_user(user).each do |layout|
      return layout if layout.is_hit?(col, row)
    end
    nil
  end

  def bot_layout
    Ship.ordered.each do |ship|
      Layout.set_location(game: self, user: user_2, ship: ship)
    end
    update_attributes(user_2_layed_out: true)
  end

  def opponent(user)
    user == user_1 ? user_2 : user_1
  end

  def next_turn
    new_turn = turn == user_1 ? user_2 : user_1
    update_attributes(turn: new_turn)
    layouts.unsunk.each(&:check_sunk)
    update_attributes(winner: user_2) if layouts.sunk_for_user(user_1).count == 5
    update_attributes(winner: user_1) if layouts.sunk_for_user(user_2).count == 5
    calculate_scores unless winner.nil?
    touch
  end

  def calculate_scores_cancel
    return unless rated && winner
    if winner == user_1
      user_1.wins   += 1
      user_2.losses += 1
      user_1.rating += 1
      user_2.rating -= 1
    elsif winner == user_2
      user_2.wins   += 1
      user_1.losses += 1
      user_2.rating += 1
      user_1.rating -= 1
    end
    user_1.save!
    user_2.save!
  end

  def calculate_scores
    return unless rated && winner
    p1 = user_1.rating
    p2 = user_2.rating
    p1_p2 = p1 + p2
    p1_r = p1.to_f / p1_p2
    p2_r = p2.to_f / p1_p2
    p1_p = (32 * p1_r).to_i
    p2_p = (32 * p2_r).to_i
    if winner == user_1
      user_1.wins   += 1
      user_2.losses += 1
      user_1.rating += p2_p
      user_2.rating -= p2_p
    elsif winner == user_2
      user_2.wins   += 1
      user_1.losses += 1
      user_2.rating += p1_p
      user_1.rating -= p1_p
    end
    user_1.save!
    user_2.save!
  end

  def attack_sinking_ship(user, opponent)
    log('attack_sinking_ship()')
    layout = get_sinking_ship(opponent)
    if layout
      move = if layout.moves.count == 1
               attack_1(user, opponent, layout.moves.first)
             else
               attack_2(user, opponent, layout.moves)
             end
      log("  returning move: #{move}")
      return move
    end
    log('  returning nil')
    nil
  end

  def get_random_move_lines(user)
    log('get_random_move_lines()')
    cols = Array.new(10, 0)
    rows = Array.new(10, 0)
    10.times do |i|
      cols[i] = moves.for_user(user).where(layout: nil, x: i).count
      rows[i] = moves.for_user(user).where(layout: nil, y: i).count
    end
    min_cols = []
    min_rows = []
    10.times do |i|
      min_cols << i if cols[i] == cols.min
      min_rows << i if rows[i] == rows.min
    end
    x = min_cols.sample
    y = min_rows.sample
    move = moves.for_user(user).where(x: x, y: y).first
    log("  move: #{move}")
    return get_totally_random_move(user) if move
    log("  returning with x: #{x}, y: #{y}")
    [x, y]
  end

  def get_random_move_spacing(user)
    log('get_random_move_spacing()')
    mvs = moves.for_user(user)
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
    get_totally_random_move(user)
  end

  def get_totally_random_move(user)
    log('get_totally_random_move()')
    x = (0..9).to_a.sample
    y = (0..9).to_a.sample
    move = moves.for_user(user).where(x: x, y: y).first
    log("  move: #{move}")
    log("  x: #{x}, y: #{y}")
    return [x, y] unless move
    get_totally_random_move(user)
  end

  def again?(user)
    r = (1..100).to_a.sample
    return true if user.id == 1 && r < 96
    return true if user.id == 2 && r < 97
    return true if user.id == 3 && r < 98
    return true if user.id == 4 && r < 99
    false
  end

  def attack_random_ship(user, opponent)
    log('attack_random_ship()')

    x, y = get_random_move_lines(user)
    layout = is_hit?(opponent, x, y)

    if layout.nil? && again?(user)
      x, y = get_random_move_spacing(user)
      layout = is_hit?(opponent, x, y)

      if layout.nil? && again?(user)
        x, y = get_random_move_lines(user)
        layout = is_hit?(opponent, x, y)
      end
    end

    move = moves.for_user(user).for_xy(x, y).first
    log("  move exists?: #{move}")
    x, y = get_totally_random_move(user) if move
    log("x: #{x} y: #{y}")

    layout = is_hit?(opponent, x, y)
    move = moves.create!(user: user, layout: layout, x: x, y: y)
    log("  move create!: #{move}")
    move.persisted?
  end

  def get_sinking_ship(user)
    layouts.unsunk_for_user(user).each do |layout|
      return layout if moves.for_layout(layout).count > 0
    end
    nil
  end

  def attack_1(user, opponent, hit)
    log('attack_1()')
    log("hit: #{hit}")
    cols = []
    rows = []

    # left of hit
    if hit.x - 1 >= 0
      move = moves.for_user(user).for_xy(hit.x - 1, hit.y).first
      log("left: #{move}")
      if move.nil?
        cols << hit.x - 1
        rows << hit.y
      end
    end
    # right of hit
    if hit.x + 1 <= 9
      move = moves.for_user(user).for_xy(hit.x + 1, hit.y).first
      log("right: #{move}")
      if move.nil?
        cols << hit.x + 1
        rows << hit.y
      end
    end
    # above hit
    if hit.y - 1 >= 0
      move = moves.for_user(user).for_xy(hit.x, hit.y - 1).first
      log("above: #{move}")
      if move.nil?
        cols << hit.x
        rows << hit.y - 1
      end
    end
    # below hit
    if hit.y + 1 <= 9
      move = moves.for_user(user).for_xy(hit.x, hit.y + 1).first
      log("below: #{move}")
      if move.nil?
        cols << hit.x
        rows << hit.y + 1
      end
    end

    log("cols: #{cols}")
    log("rows: #{rows}")

    unless cols.empty?
      r = (0..(cols.size - 1)).to_a.sample
      log("r: #{r}")
      layout = is_hit?(opponent, cols[r], rows[r])
      move = moves.create!(user: user, layout: layout, x: cols[r], y: rows[r])
      log("  move: #{move}")
      log("  move.persisted?: #{move.persisted?}")
      return true if move.persisted?
    end
    log('  returning false')
    false
  end

  def attack_2(user, opponent, hits)
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
        move = moves.for_user(user).where(x: hits[0].x, y: r).ordered.first
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
        move = moves.for_user(user).where(x: c, y: hits[0].y).ordered.first
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
    move = moves.create!(user: user, layout: layout, x: cols[r], y: rows[r])
    log("  move: #{move}")

    return move if move.persisted?

    log('  returning false')
    false
  end
end
