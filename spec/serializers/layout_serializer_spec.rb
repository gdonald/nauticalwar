# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LayoutSerializer, type: :serializer do
  let(:player_1) { build_stubbed(:player, id: 1) }
  let(:player_2) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let(:ship) { build_stubbed(:ship, id: 1) }
  let(:layout) { build_stubbed(:layout, id: 1, game: game, ship: ship, player: player_1) }
  let(:serializer) { LayoutSerializer.new(layout) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['id']).to eq(layout.id)
    expect(json['game_id']).to eq(layout.game_id)
    expect(json['player_id']).to eq(layout.player_id)
    expect(json['ship_id']).to eq(ship.id - 1)
    expect(json['x']).to eq(layout.x)
    expect(json['y']).to eq(layout.y)
    expect(json['vertical']).to eq(1)
  end
end
