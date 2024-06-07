# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::PingController < Api::ApiController
  def index
    render json: { id: @current_player ? @current_player.id : -1 }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
