# frozen_string_literal: true

class LayoutSerializer < ActiveModel::Serializer
  attributes :id, :game_id, :user_id, :ship_id, :x, :y, :vertical

  def ship_id
    object.ship_id - 1
  end

  def vertical
    object.vertical ? 1 : 0
  end
end
