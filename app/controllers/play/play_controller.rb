# frozen_string_literal: true

module Play
  class PlayController < ApplicationController
    layout 'play'

    def set_current_player
      @current_player = Player.find_by(id: session[:player_id]) if session[:player_id]

      redirect_to new_play_session_path if @current_player.nil?
    end
  end
end
