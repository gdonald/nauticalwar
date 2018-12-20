# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::PlayersController < Api::ApiController
  skip_before_action :verify_authenticity_token,
                     only: %i[create complete_google_signup account_exists]

  skip_before_action :authenticate_player!,
                     only: %i[create complete_google_signup account_exists]

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
    player = Player.complete_google_signup(google_params)
    session[:player_id] = player[:id].nil? ? 0 : player[:id]
    render json: player
  end

  def account_exists
    render json: Player.find_by(email: google_params[:email])
  end

  private

  def google_params
    params.permit(:name, :email)
  end

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
