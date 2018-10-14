# frozen_string_literal: true

class PlayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :wins, :losses, :rating, :get_last

  def get_last
    object.get_last
  end
end
