class Ship < ApplicationRecord

  validates :name, presence: true, length: { maximum: 12 }
  validates :size, presence: true, inclusion: { in: (2..5).to_a }

end
