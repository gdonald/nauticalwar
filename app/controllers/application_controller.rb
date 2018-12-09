# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def authenticate_player!
    return nil if session[:player_id].nil?
    @current_player = Player.find_by(id: session[:player_id])
    raise 'Player session not found' unless @current_player
  end
end
