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
      if layout.is_hit?(c, r)
        return true
      end
    end
    false
  end

  def bot_layout
    Ship.ordered.each do |ship|
      Layout.set_location(game: self, user: user_2, ship: ship)
    end
    update_attributes(user_2_layed_out: true)
  end

end
