# frozen_string_literal: true

class Bot < ApplicationRecord
  belongs_to :player

  validates :player, presence: true
end
