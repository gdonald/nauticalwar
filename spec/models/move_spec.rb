# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Move do
  let(:player_one) { build_stubbed(:player, id: 1) }
  let(:player_two) { build_stubbed(:player, id: 2) }
  let(:game) do
    build_stubbed(:game, id: 1, player1: player_one, player2: player_two, turn: player_one)
  end

  describe '#to_s' do
    let(:move) { build(:move, game:, player: player_one) }

    it 'returns a string' do
      expected = "Move(player: #{player_one.name} layout:  x: 0 y: 0)"
      expect(move.to_s).to eq(expected)
    end
  end

  describe 'validations' do
    describe '#layout_hits_max' do
      let(:ship) { create(:ship) }
      let!(:layout) do
        create(:layout, game:, player: player_one, ship:)
      end
      let(:move_one) do
        create(:move, game:, layout:, player: player_one)
      end
      let(:move_two) do
        create(:move, game:, layout:, player: player_two, y: 1)
      end

      before { [move_one, move_two] }

      it 'creates an error' do
        move = build(:move, game:, layout:, player: player_one)
        expect(move).to be_invalid
        expect(move.errors['layout']).to be_present
      end
    end
  end
end
