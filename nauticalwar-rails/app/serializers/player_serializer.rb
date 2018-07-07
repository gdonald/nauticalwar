# frozen_string_literal: true

class PlayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :wins, :losses, :rating, :last, :bot

  delegate :last, to: :object

  def bot
    object.bot ? 1 : 0
  end
end
