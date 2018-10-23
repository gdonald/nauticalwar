# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::PingController < Api::ApiController
  def index
    render json: { id: current_api_player.id }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
