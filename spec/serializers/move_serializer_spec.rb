# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveSerializer, type: :serializer do
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:game) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let(:ship) { create(:ship) }
  let(:layout) { create(:layout, game: game, ship: ship, player: player_1) }
  let(:move) { create(:move, game: game, layout: layout, player: player_1) }
  let(:serializer) { MoveSerializer.new(move) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['x']).to eq(move.x)
    expect(json['y']).to eq(move.y)
    expect(json['hit']).to eq('H')
  end
end
