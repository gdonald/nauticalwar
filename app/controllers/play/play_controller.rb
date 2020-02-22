# frozen_string_literal: true

class Play::PlayController < ActionController::Base
  layout 'play'

  def get_current_player
    if session[:player_id]
      @current_player = Player.find_by(id: session[:player_id])
    end

    redirect_to new_play_session_path if @current_player.nil?
  end
end
