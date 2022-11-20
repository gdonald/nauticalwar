# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Move do
  let(:player1) { build_stubbed(:player, id: 1) }
  let(:player2) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player1:, player2:, turn: player1)
  end

  describe '#to_s' do
    let(:move) { build(:move, game:, player: player1) }

    it 'returns a string' do
      expected = "Move(player: #{player1.name} layout:  x: 0 y: 0)"
      expect(move.to_s).to eq(expected)
    end
  end

  describe 'validations' do
    describe '#layout_hits_max' do
      let(:ship) { create(:ship) }
      let!(:layout) do
        create(:layout, game:, player: player1, ship:)
      end
      let(:move1) do
        create(:move, game:, layout:, player: player1)
      end
      let(:move2) do
        create(:move, game:, layout:, player: player2, y: 1)
      end

      before { [move1, move2] }

      it 'creates an error' do
        move = build(:move, game:, layout:, player: player1)
        expect(move).to be_invalid
        expect(move.errors['layout']).to be_present
      end
    end
  end
end
