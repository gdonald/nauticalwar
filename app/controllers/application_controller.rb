# frozen_string_literal: true

class ApplicationController < ActionController::Base
  after_action :custom_headers

  def current_admin
    @current_admin ||= Player.find_by(id: session[:admin_id])
  end

  def authenticate_admin!
    return nil if session[:admin_id].nil?

    @current_admin = Player.find_by(admin: true, id: session[:admin_id])
    return false unless @current_admin
  end

  def authenticate_player!
    return nil if session[:player_id].nil?

    @current_player = Player.find_by(id: session[:player_id])
    raise 'Player session not found' unless @current_player
  end

  def access_denied(_params)
    redirect_to new_admin_session_path
  end

  def custom_headers
    response.headers['Pragma'] = 'no-cache'
  end
end
