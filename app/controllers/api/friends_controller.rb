# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::FriendsController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def index
    render json: { ids: current_api_player.friend_ids }
  end

  def create
    render json: { status: current_api_player.create_friend!(params[:id]) }
  end

  def destroy
    render json: { status: current_api_player.destroy_friend!(params[:id]) }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
