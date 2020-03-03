# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#yes_no' do
    it 'returns Yes' do
      expect(helper.yes_no(true)).to eq('Yes')
    end

    it 'returns No' do
      expect(helper.yes_no(false)).to eq('No')
    end
  end

  describe '#time_limit_in_words' do
    it 'returns 5 minutes' do
      expect(helper.time_limit_in_words(300)).to eq('5 minutes')
    end

    it 'returns 15 minutes' do
      expect(helper.time_limit_in_words(900)).to eq('15 minutes')
    end

    it 'returns 1 hour' do
      expect(helper.time_limit_in_words(3600)).to eq('1 hour')
    end

    it 'returns 8 hours' do
      expect(helper.time_limit_in_words(28800)).to eq('8 hours')
    end

    it 'returns 5 minutes' do
      expect(helper.time_limit_in_words(86400)).to eq('1 day')
    end
  end

  describe '#time_left' do
    it 'returns 5 minutes' do
      freeze_time do
        expect(helper.time_left(300)).to eq('5 minutes')
      end
    end

    it 'returns 0:00' do
      freeze_time do
        expect(helper.time_left(-1)).to eq('0:00')
      end
    end
  end

  describe '#shots_per_turn_name' do
    let(:game) { build_stubbed(:game) }

    it 'returns one' do
      expect(helper.shots_per_turn_name(game)).to eq('one')
    end

    it 'returns two' do
      game.shots_per_turn = 2
      expect(helper.shots_per_turn_name(game)).to eq('two')
    end

    it 'returns three' do
      game.shots_per_turn = 3
      expect(helper.shots_per_turn_name(game)).to eq('three')
    end

    it 'returns four' do
      game.shots_per_turn = 4
      expect(helper.shots_per_turn_name(game)).to eq('four')
    end

    it 'returns five' do
      game.shots_per_turn = 5
      expect(helper.shots_per_turn_name(game)).to eq('five')
    end
  end

  describe '#shots_per_turn_name' do
    let(:player) { build_stubbed(:player) }

    it 'returns Seaman Recruit' do
      expect(helper.rank_name('e1')).to eq('Seaman Recruit')
    end

    it 'returns Seaman Apprentice' do
      expect(helper.rank_name('e2')).to eq('Seaman Apprentice')
    end

    it 'returns Seaman' do
      expect(helper.rank_name('e3')).to eq('Seaman')
    end

    it 'returns Petty Officer Third Class' do
      expect(helper.rank_name('e4')).to eq('Petty Officer Third Class')
    end

    it 'returns Petty Officer Second Class' do
      expect(helper.rank_name('e5')).to eq('Petty Officer Second Class')
    end

    it 'returns Petty Officer First Class' do
      expect(helper.rank_name('e6')).to eq('Petty Officer First Class')
    end

    it 'returns Chief Petty Officer' do
      expect(helper.rank_name('e7')).to eq('Chief Petty Officer')
    end

    it 'returns Senior Chief Petty Officer' do
      expect(helper.rank_name('e8')).to eq('Senior Chief Petty Officer')
    end

    it 'returns Master Chief Petty Officer' do
      expect(helper.rank_name('e9')).to eq('Master Chief Petty Officer')
    end

    it 'returns Ensign' do
      expect(helper.rank_name('o1')).to eq('Ensign')
    end

    it 'returns Lieutenant Junior Grade' do
      expect(helper.rank_name('o2')).to eq('Lieutenant Junior Grade')
    end

    it 'returns Lieutenant' do
      expect(helper.rank_name('o3')).to eq('Lieutenant')
    end

    it 'returns Lieutenant Commander' do
      expect(helper.rank_name('o4')).to eq('Lieutenant Commander')
    end

    it 'returns Commander' do
      expect(helper.rank_name('o5')).to eq('Commander')
    end

    it 'returns Captain' do
      expect(helper.rank_name('o6')).to eq('Captain')
    end

    it 'returns Rear Admiral Lower Half' do
      expect(helper.rank_name('o7')).to eq('Rear Admiral Lower Half')
    end

    it 'returns Rear Admiral' do
      expect(helper.rank_name('o8')).to eq('Rear Admiral')
    end

    it 'returns Vice Admiral' do
      expect(helper.rank_name('o9')).to eq('Vice Admiral')
    end

    it 'returns Admiral' do
      expect(helper.rank_name('o10')).to eq('Admiral')
    end

    it 'returns Fleet Admiral' do
      expect(helper.rank_name('o11')).to eq('Fleet Admiral')
    end
  end
end
