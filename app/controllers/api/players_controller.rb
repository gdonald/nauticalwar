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

  def complete_google_signup
    render json: Player.complete_google_signup(google_player_params)
  end

  def google_account_exists
    render json: Player.google_account_exists(google_email_params)
  end

  private

  def google_email_params
    params.permit(:email)
  end

  def google_player_params
    params.permit(:name, :email)
  end

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
