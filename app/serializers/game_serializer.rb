# frozen_string_literal: true

class GameSerializer < ActiveModel::Serializer
  attributes :id,
             :player_1_id,
             :player_2_id,
             :player_1_name,
             :player_2_name,
             :turn_id,
             :winner_id,
             :updated_at,
             :player_1_layed_out,
             :player_2_layed_out,
             :rated,
             :five_shot,
             :t_limit

  def t_limit
    object.t_limit
  end

  def player_1_name
    object.player_1.name
  end

  def player_2_name
    object.player_2.name
  end

  def winner_id
    object.winner ? object.winner_id : '0'
  end

  def player_1_layed_out
    object.player_1_layed_out ? '1' : '0'
  end

  def player_2_layed_out
    object.player_2_layed_out ? '1' : '0'
  end

  def rated
    object.rated ? '1' : '0'
  end

  def five_shot
    object.five_shot ? '1' : '0'
  end
end
