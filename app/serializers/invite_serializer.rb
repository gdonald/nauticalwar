# frozen_string_literal: true

class InviteSerializer < ActiveModel::Serializer
  attributes :id,
             :player_1_id,
             :player_2_id,
             :player_1_name,
             :player_2_name,
             :player_1_rating,
             :player_2_rating,
             :created_at,
             :rated,
             :shots_per_turn,
             :time_limit,
             :game_id

  def rated
    object.rated ? '1' : '0'
  end

  def shots_per_turn
    object.shots_per_turn
  end

  def player_1_name
    object.player_1.name
  end

  def player_2_name
    object.player_2.name
  end

  def player_1_rating
    object.player_1.rating
  end

  def player_2_rating
    object.player_2.rating
  end
end
