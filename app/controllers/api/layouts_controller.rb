# frozen_string_literal: true

class Api::LayoutsController < Api::ApiController # rubocop:disable Style/ClassAndModuleChildren, Metrics/LineLength
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    game = current_api_player.active_games.where(id: params[:game_id]).first
    if game
      game.create_ship_layouts(current_api_player, params[:layout])
      render json: game
    else
      render json: { errors: 'game not found' }
    end
  end
end
