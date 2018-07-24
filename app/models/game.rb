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

  def hits(user)
    moves.where(user: user).where.not(layout: nil).ordered
  end

  def misses(user)
    moves.where(user: user).where(layout: nil).ordered
  end

  def last(user)
    limit = five_shot ? 5 : 1
    moves.where(user: user).limit(limit).ordered
  end
  
  def is_hit?(user, c, r)
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
  
end
