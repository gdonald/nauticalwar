class Invite < ApplicationRecord

  attr_accessor :game_id

  belongs_to :user_1, class_name: 'User', foreign_key: 'user_1_id'
  belongs_to :user_2, class_name: 'User', foreign_key: 'user_2_id'
  
  validates :user_1, presence: true
  validates :user_2, presence: true
  validates :user_2, uniqueness: { scope: :user_1_id, message: 'Invite already exists' }
  
  validates :rated, inclusion: [true, false]
  validates :five_shot, inclusion: [true, false]
  validates :time_limit, presence: true
  
  validate :cannot_invite_self

  scope :ordered, -> { order(created_at: :asc) }
  
  def cannot_invite_self
    errors.add(:user_2, 'Cannot invite self') if user_1 == user_2
  end

end
