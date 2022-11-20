# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InviteSerializer, type: :serializer do
  let(:player1) { build_stubbed(:player, id: 1) }
  let(:player2) { build_stubbed(:player, id: 1) }
  let(:invite) { build_stubbed(:invite, id: 1, player1:, player2:) }
  let(:serializer) { described_class.new(invite) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['id']).to eq(invite.id)
    expect(json['game_id']).to be_nil
    expect(json['player1_id']).to eq(invite.player1_id)
    expect(json['player2_id']).to eq(invite.player2_id)
    expect(json['rated']).to eq('1')
    expect(json['shots_per_turn']).to eq(1)
    expect(json['time_limit']).to eq(86_400)
  end
end
