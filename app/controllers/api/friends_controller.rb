# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::FriendsController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def index
    ids = current_api_player.friends.collect(&:player_2_id)
    render json: { ids: ids }
  end

  def create
    status = -1
    player = Player.active.find_by(id: params[:p])
    unless current_api_player.friends.include?(player)
      Friend.create!(player_1: current_api_player, player_2: player)
      status = player.id
    end
    render json: { status: status }
  end

  def destroy
    status = -1
    player = Player.find_by(id: params[:id])
    if player
      friend = current_api_player.friends.where(player_2: player).first
      friend&.destroy
      status = player.id
    end
    render json: { status: status }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
