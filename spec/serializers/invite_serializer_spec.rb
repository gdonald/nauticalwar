# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InviteSerializer, type: :serializer do
  let(:player_1) { build_stubbed(:player, id: 1) }
  let(:player_2) { build_stubbed(:player, id: 1) }
  let(:invite) { build_stubbed(:invite, id: 1, player_1: player_1, player_2: player_2) }
  let(:serializer) { InviteSerializer.new(invite) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['id']).to eq(invite.id)
    expect(json['game_id']).to be_nil
    expect(json['player_1_id']).to eq(invite.player_1_id)
    expect(json['player_2_id']).to eq(invite.player_2_id)
    expect(json['rated']).to eq('1')
    expect(json['shots_per_turn']).to eq(1)
    expect(json['time_limit']).to eq(86_400)
  end
end
