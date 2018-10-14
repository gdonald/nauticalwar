# frozen_string_literal: true

class Api::PlayersController < Api::ApiController
  respond_to :json

  def index
    render json: Player.list(current_api_player)
  end

  def activity
    render json: { activity: current_api_player.activity }
  end
end
