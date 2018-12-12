# frozen_string_literal: true

class PlayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :wins, :losses, :rating, :last, :bot

  def last
    object.last
  end

  def bot
    object.bot ? 1 : 0
  end
end
