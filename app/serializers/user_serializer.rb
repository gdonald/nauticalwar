# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :wins, :losses, :rating, :get_last

  def get_last
    object.get_last
  end
end
