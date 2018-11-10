# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerSerializer, type: :serializer do
  let(:player) { create(:player) }
  let(:serializer) { PlayerSerializer.new(player) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json) }

  it 'is json' do
    expect(json['id']).to eq(player.id)
    expect(json['name']).to eq(player.name)
    expect(json['wins']).to eq(0)
    expect(json['losses']).to eq(0)
    expect(json['rating']).to eq(1200)
    expect(json['last']).to eq(player.last)
  end
end
