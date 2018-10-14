# frozen_string_literal: true

class Api::PingController < Api::ApiController
  def index
    render json: { id: current_api_player.id }
  end
end
