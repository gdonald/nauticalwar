# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MoveSerializer, type: :serializer do
  let(:player_one) { build_stubbed(:player, id: 1) }
  let(:player_two) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player1: player_one, player2: player_two, turn: player_one)
  end
  let(:ship) { build_stubbed(:ship, id: 1) }
  let(:layout) { build_stubbed(:layout, id: 1, game:, ship:, player: player_one) }
  let(:move) { build_stubbed(:move, id: 1, game:, layout:, player: player_one) }
  let(:serializer) { described_class.new(move) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['x']).to eq(move.x)
    expect(json['y']).to eq(move.y)
    expect(json['hit']).to eq('H')
  end
end
