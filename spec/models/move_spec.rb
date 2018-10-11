# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Move, type: :model do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:game) { create(:game, user_1: user_1, user_2: user_2, turn: user_1) }

  describe '#to_s' do
    let(:move) { build(:move, game: game, user: user_1) }

    it 'returns a string' do
      expected = "Move(user: #{user_1.username} layout:  x: 0 y: 0)"
      expect(move.to_s).to eq(expected)
    end
  end

  describe 'validations' do
    describe '#layout_hits_max' do
      let(:ship) { create(:ship) }
      let!(:layout) { create(:layout, game: game, user: user_1, ship: ship) }
      let!(:move_1) { create(:move, game: game, layout: layout, user: user_1) }
      let!(:move_2) { create(:move, game: game, layout: layout, user: user_2, y: 1) }

      it 'creates an error' do
        move = build(:move, game: game, layout: layout, user: user_1)
        expect(move).to be_invalid
        expect(move.errors['layout']).to be_present
      end
    end
  end
end
