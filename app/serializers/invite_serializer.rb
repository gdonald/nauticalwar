# frozen_string_literal: true

class InviteSerializer < ActiveModel::Serializer
  attributes :id,
             :player_1_id,
             :player_2_id,
             :created_at,
             :rated,
             :five_shot,
             :time_limit,
             :game_id

  def rated
    object.rated ? '1' : '0'
  end

  def five_shot
    object.five_shot ? '1' : '0'
  end
end
