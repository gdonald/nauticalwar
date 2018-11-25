# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::GamesController < Api::ApiController
  skip_before_action :verify_authenticity_token,
                     only: %i[destroy cancel attack skip]
  respond_to :json

  def index
    render json: current_api_player.active_games.ordered
  end

  def count
    render json: { count: current_api_player.active_games.count }
  end

  def next
    game = current_api_player.next_game
    render json: { status: status(game) }
  end

  def skip
    game = current_api_player.skip_game!(params[:id])
    render json: { status: status(game) }
  end

  def destroy
    game = current_api_player.destroy_game!(params[:id])
    render json: { status: status(game) }
  end

  def cancel
    game = current_api_player.cancel_game!(params[:id])
    render json: { status: status(game) }
  end

  def my_turn
    render json: { status: current_api_player.my_turn(params[:id]) }
  end

  def show
    result = current_api_player.player_game(params[:id])
    render_game(result)
  end

  def opponent
    result = current_api_player.opponent_game(params[:id])
    render_game(result)
  end

  def attack # rubocop:disable Metrics/MethodLength
    game = Game.find_game(current_api_player, params[:id])
    if game
      if game.can_attack?(current_api_player)
        current_api_player.attack!(game, params)
        render json: { status: 1 }
      else
        render json: { status: -1 }
      end
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

  private

  def status(game)
    game.nil? ? -1 : game.id
  end

  def render_game(result)
    if result
      klass = ActiveModelSerializers::SerializableResource
      render json: {
        game: klass.new(result[:game], {}).as_json,
        layouts: klass.new(result[:layouts], {}).as_json,
        moves: klass.new(result[:moves], {}).as_json
      }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
