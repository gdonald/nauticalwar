# frozen_string_literal: true

class Play::RanksController < Play::PlayController
  before_action :get_current_player

  def index
    @ranks = []
    @ranks << (1..9).collect { |n| "e#{n}" }
    @ranks << (1..11).collect { |n| "o#{n}" }
    @ranks.flatten!
  end
end
