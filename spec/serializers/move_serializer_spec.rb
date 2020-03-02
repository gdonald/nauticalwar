# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveSerializer, type: :serializer do
  let(:player_1) { build_stubbed(:player, id: 1) }
  let(:player_2) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let(:ship) { build_stubbed(:ship, id: 1) }
  let(:layout) { build_stubbed(:layout, id: 1, game: game, ship: ship, player: player_1) }
  let(:move) { build_stubbed(:move, id: 1, game: game, layout: layout, player: player_1) }
  let(:serializer) { MoveSerializer.new(move) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['x']).to eq(move.x)
    expect(json['y']).to eq(move.y)
    expect(json['hit']).to eq('H')
  end
end
