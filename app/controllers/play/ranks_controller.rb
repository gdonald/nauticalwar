# frozen_string_literal: true

module Play
  class RanksController < Play::PlayController
    before_action :set_current_player

    def index
      @ranks = []
      @ranks << (1..9).collect { |n| "e#{n}" }
      @ranks << (1..11).collect { |n| "o#{n}" }
      @ranks.flatten!
    end
  end
end
