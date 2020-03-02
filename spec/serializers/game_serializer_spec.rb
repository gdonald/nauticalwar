# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameSerializer, type: :serializer do
  let(:player_1) { build_stubbed(:player, id: 1) }
  let(:player_2) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let(:serializer) { GameSerializer.new(game) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    travel_to game.updated_at do
      expect(json['id']).to eq(game.id)
      expect(json['player_1_id']).to eq(game.player_1_id)
      expect(json['player_2_id']).to eq(game.player_2_id)
      expect(json['player_1_name']).to eq(player_1.name)
      expect(json['player_2_name']).to eq(player_2.name)
      expect(json['turn_id']).to eq(game.player_1_id)
      expect(json['winner_id']).to eq('0')
      expect(json['updated_at']).to eq(game.updated_at.iso8601)
      expect(json['player_1_layed_out']).to eq('0')
      expect(json['player_2_layed_out']).to eq('0')
      expect(json['rated']).to eq('1')
      expect(json['shots_per_turn']).to eq(1)
      expect(json['t_limit']).to eq(86_400)
    end
  end
end
