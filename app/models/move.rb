class Move < ApplicationRecord

  belongs_to :game
  belongs_to :user
  belongs_to :layout, optional: true

  validates :x, inclusion: { in: (0..9).to_a }
  validates :y, inclusion: { in: (0..9).to_a }

  validates :game, uniqueness: { scope: %i[user x y] }

  scope :ordered, -> { order(id: :asc) }
  
end
