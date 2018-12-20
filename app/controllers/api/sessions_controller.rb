# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::SessionsController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]
  skip_before_action :authenticate_player!

  def create
    player = Player.authenticate(create_params)
    session[:player_id] = player[:id].nil? ? 0 : player[:id]
    render json: player
  end

  def destroy
    reset_session
  end

  private

  def create_params
    params.permit(:email, :password)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
