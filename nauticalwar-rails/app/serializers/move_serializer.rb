# frozen_string_literal: true

class MoveSerializer < ActiveModel::Serializer
  attributes :x, :y, :hit

  def hit
    object.layout.nil? ? 'M' : 'H'
  end
end
