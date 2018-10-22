# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Move, type: :model do # rubocop:disable Metrics/BlockLength
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:game) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1)
  end

  describe '#to_s' do
    let(:move) { build(:move, game: game, player: player_1) }

    it 'returns a string' do
      expected = "Move(player: #{player_1.name} layout:  x: 0 y: 0)"
      expect(move.to_s).to eq(expected)
    end
  end

  describe 'validations' do
    describe '#layout_hits_max' do
      let(:ship) { create(:ship) }
      let!(:layout) do
        create(:layout, game: game, player: player_1, ship: ship)
      end
      let!(:move_1) do
        create(:move, game: game, layout: layout, player: player_1)
      end
      let!(:move_2) do
        create(:move, game: game, layout: layout, player: player_2, y: 1)
      end

      it 'creates an error' do
        move = build(:move, game: game, layout: layout, player: player_1)
        expect(move).to be_invalid
        expect(move.errors['layout']).to be_present
      end
    end
  end
end
