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
    result = current_api_player.find_game(params[:id])
    render_game(result)
  end

  def opponent
    result = current_api_player.find_game(params[:id], true)
    render_game(result)
  end

  def attack # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/LineLength
    status = -1
    game = Game.find_game(current_api_player, params[:id])
    if game
      if game.winner.nil? && game.turn == current_api_player
        opponent = game.opponent(current_api_player)
        shots = JSON.parse(params[:s]).slice(0, game.five_shot ? 5 : 1)
        shots.each do |s|
          move = game.moves.for_player(current_api_player)
                     .where(x: s['x'], y: s['y']).first
          next unless move.nil?

          layout_player = game.player_1 == current_api_player ? game.player_2 : game.player_1 # rubocop:disable Metrics/LineLength
          layout = game.hit?(layout_player, s['x'], s['y'])
          Move.create!(game: game,
                       player: current_api_player,
                       x: s['x'], y: s['y'],
                       layout: layout)
          layout&.sunk?
        end
        status = 1
        game.next_turn
        if game.winner.nil?
          if opponent.bot # rubocop:disable Metrics/BlockNesting
            if game.five_shot # rubocop:disable Metrics/BlockNesting
              opponent.strength.times do
                move = game.attack_sinking_ship(opponent, current_api_player) # rubocop:disable Metrics/LineLength
                game.attack_random_ship(opponent, current_api_player) if move.nil? # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
              end
              (5 - opponent.strength).times do
                game.attack_random_ship(opponent, current_api_player)
              end
            else
              move = game.attack_sinking_ship(opponent, current_api_player) # rubocop:disable Metrics/LineLength
              game.attack_random_ship(opponent, current_api_player) if move.nil? # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
            end
            game.next_turn if game.winner.nil? # rubocop:disable Metrics/BlockNesting, Metrics/LineLength
            opponent.update_attributes(activity: opponent.activity + 1)
          else
            new_activity = current_api_player.activity + 1
            current_api_player.update_attributes(activity: new_activity)
          end
        end
      end
      render json: { status: status }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

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
