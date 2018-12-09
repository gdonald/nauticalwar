# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::PlayersController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create]

  respond_to :json

  def index
    render json: Player.list(@current_player)
  end

  def activity
    render json: { activity: @current_player.activity }
  end

  def create
    render json: Player.create_player(player_params)
  end

  private

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
