class InviteSerializer < ActiveModel::Serializer
  attributes :id, :user_id_1, :user_id_2, :created_at, :rated, :five_shot, :time_limit

  def rated
    object.rated ? '1' : '0'
  end

  def five_shot
    object.five_shot ? '1' : '0'
  end

end
