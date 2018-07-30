class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true, length: { maximum: 12 }
  validates :bot, inclusion: [true, false]
  
  has_many :games_1, foreign_key: :user_1_id, class_name: 'Game'
  has_many :games_2, foreign_key: :user_2_id, class_name: 'Game'

  has_many :invites_1, foreign_key: :user_1_id, class_name: 'Invite'
  has_many :invites_2, foreign_key: :user_2_id, class_name: 'Invite'
  
  # def games
  #  games_1.or(games_2)
  # end

  def to_s
    username
  end
  
  def active_games
    games_1.where(del_user_1: false).or(games_2.where(del_user_2: false))
  end
  
  def invites
    invites_1.or(invites_2)
  end

  def self.list(user)
    ids = User.select(:id).where(bot: true).collect { |u| u.id }
    ids += User.select(:id).where(arel_table[:rating].gteq(user.rating)).order(rating: :asc ).limit(15).collect { |u| u.id }
    ids += User.select(:id).where(arel_table[:rating].lteq(user.rating)).order(rating: :desc).limit(15).collect { |u| u.id }
    ids.uniq!
    User.where(id: ids).order(rating: :desc)
  end
  
  def self.generate_password(length)
    (('a'..'z').to_a + (10..99).to_a + ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_'] * 10).shuffle[0, length].join
  end

  def get_last
    return 0 if bot
    if last_sign_in_at
      return 0 if last_sign_in_at > 1.hour.ago
      return 1 if last_sign_in_at > 1.day.ago
      return 2 if last_sign_in_at > 3.days.ago
    end
    3
  end
end
