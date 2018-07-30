class Game < ApplicationRecord

  belongs_to :user_1, class_name: 'User', foreign_key: 'user_1_id'
  belongs_to :user_2, class_name: 'User', foreign_key: 'user_2_id'
  belongs_to :turn, class_name: 'User', foreign_key: 'turn_id'
  belongs_to :winner, class_name: 'User', foreign_key: 'winner_id', optional: true

  has_many :layouts
  has_many :moves

  validates :user_2, uniqueness: { scope: :user_1_id }
  validates :rated, presence: true
  validates :five_shot, presence: true
  validates :time_limit, presence: true
  validates :del_user_1, inclusion: [true, false]
  validates :del_user_2, inclusion: [true, false]
  
  scope :ordered, -> { order(created_at: :asc) }

  def moves_for_user(user)
    moves.where(user: user).ordered
  end

  def last(user)
    limit = five_shot ? 5 : 1
    moves.where(user: user).limit(limit).ordered.first
  end
  
  def is_hit?(user, c, r)
    reload
    layouts.each do |layout|
      return layout if layout.is_hit?(c, r)
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
    turn = turn == user_1 ? user_2 : user_1
    update_attributes(turn: turn)
    layouts.unsunk.each do |layout|
      layout.check_sunk
    end
    update_attributes(winner: user_2) if layouts.sunk_for_user(user_1).count == 5
    update_attributes(winner: user_1) if layouts.sunk_for_user(user_2).count == 5
    calculate_scores unless winner.nil?
  end

  def calculate_scores
    return unless rated
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
    else
      user_2.wins   += 1
      user_1.losses += 1
      user_2.rating += p1_p
      user_1.rating -= p1_p
    end
    user_1.save!
    user_2.save!
  end

  def attack_sinking_ship(user, opponent)
    layout = get_sinking_ship(opponent)
    if layout
      if layout.moves.count == 1
        move = attack_1(user, opponent, layout.moves.first)
      else
        move = attack_2(user, opponent, layout.moves)
      end
      return move
    end
    false
  end

  def get_sinking_ship(user)
    layouts.unsunk_for_user(user).each do |layout|
      if moves.for_layout(layout).count > 0
        return layout
      end
    end
    nil
  end
  
  def attack_1(user, opponent, hit)
    cols = []
    rows = []

    if hit.x - 1 >= 0
      move = moves.for_user(user).for_xy(hit.x - 1, hit.y)
      if move.nil?
        cols << move.x - 1
        rows << move.y
      end
    end
    if hit.x + 1 <= 9
      move = moves.for_user(user).for_xy(hit.x + 1, hit.y)
      if move.nil?
        cols << move.x + 1
        rows << move.y
      end
    end
    if hit.y - 1 >= 0
      move = moves.for_user(user).for_xy(hit.x, hit.y - 1)
      if move.nil?
        cols << move.x
        rows << move.y - 1
      end
    end
    if hit.y + 1 <= 9
      move = moves.for_user(user).for_xy(hit.x, hit.y + 1)
      if move.nil?
        cols << move.x
        rows << move.y + 1
      end
    end
    if cols.size > 0
      r = rand(0, cols.size - 1)
      layout = game.is_hit?(opponent, cs[r], rs[r])
      move = moves.create(user: user, layout: layout, x: cols[r], y: rows[r])
      return move if move.persisted?
    end
    false
  end
  
end
