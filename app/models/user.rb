class User < ApplicationRecord

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true, length: { maximum: 12 }

  has_many :games_1, foreign_key: :user_id_1, class_name: 'Game'
  has_many :games_2, foreign_key: :user_id_2, class_name: 'Game'

  has_many :invites_1, foreign_key: :user_id_1, class_name: 'Invite'
  has_many :invites_2, foreign_key: :user_id_2, class_name: 'Invite'
  
  def games
    games_1.or(games_2).order(updated_at: :asc)
  end

  def invites
    invites_1.or(invites_2).order(created_at: :asc)
  end
  
  def self.generate_password(length)
    (('a'..'z').to_a + (10..99).to_a + ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_'] * 10).shuffle[0, length].join
  end
  
end
