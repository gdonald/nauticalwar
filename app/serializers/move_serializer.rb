class MoveSerializer < ActiveModel::Serializer
  attributes :id, :game_id, :user_id, :layout_id, :x, :y

end
