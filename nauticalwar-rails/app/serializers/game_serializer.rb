# frozen_string_literal: true

class GameSerializer < ActiveModel::Serializer
  attributes :id,
             :player1_id,
             :player2_id,
             :player1_name,
             :player2_name,
             :turn_id,
             :winner_id,
             :updated_at,
             :player1_layed_out,
             :player2_layed_out,
             :rated,
             :shots_per_turn,
             :t_limit

  delegate :t_limit, to: :object

  def player1_name
    object.player1.name
  end

  def player2_name
    object.player2.name
  end

  def winner_id
    object.winner ? object.winner_id : '0'
  end

  def player1_layed_out
    object.player1_layed_out ? '1' : '0'
  end

  def player2_layed_out
    object.player2_layed_out ? '1' : '0'
  end

  def rated
    object.rated ? '1' : '0'
  end

  delegate :shots_per_turn, to: :object
end
