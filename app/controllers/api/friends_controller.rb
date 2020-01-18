# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::FriendsController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def index
    render json: { ids: @current_player.friends_player_ids }
  end

  def show
    render json: { status: @current_player.is_friend(params[:id]) }
  end

  def create
    render json: { status: @current_player.create_friend!(params[:id]) }
  end

  def destroy
    render json: { status: @current_player.destroy_friend!(params[:id]) }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
