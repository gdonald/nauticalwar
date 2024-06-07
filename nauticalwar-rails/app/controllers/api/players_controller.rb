# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::PlayersController < Api::ApiController
  skip_before_action :verify_authenticity_token,
                     only: %i[create complete_google_signup account_exists
                              locate_account reset_password]

  skip_before_action :authenticate_player!,
                     only: %i[create complete_google_signup account_exists
                              locate_account reset_password]

  respond_to :json

  # TODO: handle search
  def index
    if params[:game_id]
      render json: Player.list_for_game(params[:game_id])
    else
      render json: Player.list(@current_player)
    end
  end

  def show
    render json: Player.find_by(id: params[:id])
  end

  def activity
    render json: { activity: @current_player.activity }
  end

  def create
    render json: Player.create_player(player_params)
  end

  def complete_google_signup
    player = Player.complete_google_signup(google_params)
    render json: player
  end

  def locate_account
    render json: Player.locate_account(locate_params)
  end

  def account_exists
    player = Player.find_by(email: google_params[:email])
    session[:player_id] = player.nil? ? 0 : player.id
    render json: player
  end

  def reset_password
    player = Player.reset_password(reset_params)
    render json: { id: player[:id].nil? ? 0 : player[:id] }
  end

  private

  def locate_params
    params.permit(:email)
  end

  def google_params
    params.permit(:name, :email)
  end

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def reset_params
    params.permit(:token, :password, :password_confirmation)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
