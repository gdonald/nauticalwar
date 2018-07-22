class LayoutSerializer < ActiveModel::Serializer
  attributes :id, :game_id, :user_id, :ship_id, :x, :y, :vertical

  def vertical
    object.vertical ? '1' : '0'
  end

end
