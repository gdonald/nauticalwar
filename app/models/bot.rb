# frozen_string_literal: true

class Bot < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
end
