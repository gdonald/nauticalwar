# frozen_string_literal: true

class InviteSerializer < ActiveModel::Serializer
  attributes :id,
             :player1_id,
             :player2_id,
             :player1_name,
             :player2_name,
             :player1_rating,
             :player2_rating,
             :created_at,
             :rated,
             :shots_per_turn,
             :time_limit,
             :game_id

  def rated
    object.rated ? '1' : '0'
  end

  delegate :shots_per_turn, to: :object

  def player1_name
    object.player1.name
  end

  def player2_name
    object.player2.name
  end

  def player1_rating
    object.player1.rating
  end

  def player2_rating
    object.player2.rating
  end
end
