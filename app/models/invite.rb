class Invite < ApplicationRecord

  belongs_to :user_1, class_name: 'User', foreign_key: 'user_id_1'
  belongs_to :user_2, class_name: 'User', foreign_key: 'user_id_2'
  
  validates :user_1, presence: true
  validates :user_2, presence: true
  validates :user_2, uniqueness: { scope: :user_id_1 }
  
  validates :rated, presence: true
  validates :five_shot, presence: true
  validates :time_limit, presence: true

  validate :cannot_invite_self

  def cannot_invite_self
    errors.add(:user_2, 'Cannot invite self') if user_1 == user_2
  end

end
