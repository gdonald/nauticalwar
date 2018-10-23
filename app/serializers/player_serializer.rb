# frozen_string_literal: true

class PlayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :wins, :losses, :rating, :last

  def last
    object.last
  end
end
