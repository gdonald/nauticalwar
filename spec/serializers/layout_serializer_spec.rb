# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LayoutSerializer, type: :serializer do
  let(:player_one) { build_stubbed(:player, id: 1) }
  let(:player_two) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player1: player_one, player2: player_two, turn: player_one)
  end
  let(:ship) { build_stubbed(:ship, id: 1) }
  let(:layout) { build_stubbed(:layout, id: 1, game:, ship:, player: player_one) }
  let(:serializer) { described_class.new(layout) }
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
