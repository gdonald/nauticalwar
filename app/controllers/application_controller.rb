# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def current_admin
    @current_admin
  end

  def authenticate_admin!
    return nil if session[:admin_id].nil?
    @current_admin = Player.find_by(id: session[:admin_id])
    redirect_to new_admin_session_path unless @current_admin
  end

  def authenticate_player!
    return nil if session[:player_id].nil?
    @current_player = Player.find_by(id: session[:player_id])
    raise 'Player session not found' unless @current_player
  end
end
