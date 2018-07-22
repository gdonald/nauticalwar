class InviteSerializer < ActiveModel::Serializer
  attributes :id, :user_1_id, :user_2_id, :created_at, :rated, :five_shot, :time_limit, :game_id

  def rated
    object.rated ? '1' : '0'
  end

  def five_shot
    object.five_shot ? '1' : '0'
  end

end
