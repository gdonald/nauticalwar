# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameSerializer, type: :serializer do
  let(:player1) { build_stubbed(:player, id: 1) }
  let(:player2) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player1:, player2:, turn: player1)
  end
  let(:serializer) { described_class.new(game) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    travel_to game.updated_at do
      expect(json['id']).to eq(game.id)
      expect(json['player1_id']).to eq(game.player1_id)
      expect(json['player2_id']).to eq(game.player2_id)
      expect(json['player1_name']).to eq(player1.name)
      expect(json['player2_name']).to eq(player2.name)
      expect(json['turn_id']).to eq(game.player1_id)
      expect(json['winner_id']).to eq('0')
      expect(json['updated_at']).to eq(game.updated_at.iso8601)
      expect(json['player1_layed_out']).to eq('0')
      expect(json['player2_layed_out']).to eq('0')
      expect(json['rated']).to eq('1')
      expect(json['shots_per_turn']).to eq(1)
      expect(json['t_limit']).to eq(86_400)
    end
  end
end
