class Invite < ApplicationRecord

  attr_accessor :game_id

  belongs_to :user_1, class_name: 'User', foreign_key: 'user_id_1'
  belongs_to :user_2, class_name: 'User', foreign_key: 'user_id_2'
  
  validates :user_1, presence: true
  validates :user_2, presence: true
  validates :user_2, uniqueness: { scope: :user_id_1, message: 'Invite already exists' }
  
  validates :rated, inclusion: [true, false]
  validates :five_shot, inclusion: [true, false]
  validates :time_limit, presence: true

  validate :cannot_invite_self

  scope :ordered, -> { order(created_at: :asc) }
  
  def cannot_invite_self
    errors.add(:user_2, 'Cannot invite self') if user_1 == user_2
  end

  def handle_bot
    game = Game.create(user_1: user_1, user_2: user_2, turn: user_1, rated: rated, time_limit: time_limit, five_shot: five_shot)
    if game.persisted?
      invite.delete
      Ship.ordered.each do |ship|
        layout = Layout.create(game: game, user: user_2, ship: ship)
        layout.set_location if layout.persisted?
      end
    end
  end
end
