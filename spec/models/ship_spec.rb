# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ship, type: :model do
  describe '#to_s' do
    let(:ship) { create(:ship) }

    it 'returns a string' do
      expected = "Ship(name: #{ship.name}, size: 2)"
      expect(ship.to_s).to eq(expected)
    end
  end
end
