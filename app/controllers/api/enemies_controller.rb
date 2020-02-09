# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::EnemiesController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def create
    render json: { status: @current_player.create_enemy!(params[:id]) }
  end

  # TODO: add to android
  def destory
    render json: { status: @current_player.destroy_enemy!(params[:id]) }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
