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
end
