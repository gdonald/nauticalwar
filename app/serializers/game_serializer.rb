class GameSerializer < ActiveModel::Serializer
  attributes :id, :user_1_id, :user_2_id, :user_1_username, :user_2_username, :turn_id, :winner_id, :updated_at, :user_1_layed_out, :user_2_layed_out, :rated, :five_shot, :time_limit

  def user_1_username
    object.user_1.username
  end

  def user_2_username
    object.user_2.username
  end
  
  def winner_id
    object.winner ? object.winner_id : '0'
  end
  
  def user_1_layed_out
    object.user_1_layed_out ? '1' : '0'
  end

  def user_2_layed_out
    object.user_2_layed_out ? '1' : '0'
  end
  
  def rated
    object.rated ? '1' : '0'
  end

  def five_shot
    object.five_shot ? '1' : '0'
  end

end
