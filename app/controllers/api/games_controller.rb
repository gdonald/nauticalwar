# frozen_string_literal: true

class Api::GamesController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[destroy cancel attack skip]

  respond_to :json

  def index
    render json: current_api_player.active_games.ordered
  end

  def count
    render json: { count: current_api_player.active_games.count }
  end

  def next; end

  def skip
    status = -1
    game = Game.find_game(current_api_player, params[:id])
    if game && game.winner.nil? && game.turn != current_api_player && game.t_limit <= 0
      game.next_turn
      status = 1
    end
    render json: { status: status }
  end

  def destroy
    status = -1
    game = Game.find_game(current_api_player, params[:id])
    if game&.winner
      status = game.id
      if game.player_1 == current_api_player
        if game.player_2.bot
          game.destroy
        else
          game.update_attributes(del_player_1: true)
        end
      elsif game.player_2 == current_api_player
        game.update_attributes(del_player_2: true)
      end
      game.destroy if game.del_player_1 && game.del_player_2
    end
    render json: { status: status }
  end

  def cancel
    status = -1
    game = Game.find_game(current_api_player, params[:id])
    if game
      if game.t_limit < 0
        # opponent won't layout
        if current_api_player == game.player_1 && game.player_1_layed_out && !game.player_2_layed_out
          game.update_attributes(winner: game.player_1)
        elsif current_api_player == game.player_2 && game.player_2_layed_out && !game.player_1_layed_out
          game.update_attributes(winner: game.player_2)

        # opponent won't play
        elsif current_api_player != game.turn
          if current_api_player == game.player_1
            game.update_attributes(winner: game.player_1)
          else
            game.update_attributes(winner: game.player_2)
          end

        # i'm giving up
        elsif current_api_player == game.turn
          if current_api_player == game.player_1
            game.update_attributes(winner: game.player_2)
          else
            game.update_attributes(winner: game.player_1)
          end
        end
      else
        if current_api_player == game.player_1
          game.update_attributes(winner: game.player_2)
        else
          game.update_attributes(winner: game.player_1)
        end
      end
      game.calculate_scores_cancel
    end
    render json: game
  end

  def my_turn
    game = Game.find_game(current_api_player, params[:id])
    status = game && game.turn == current_api_player ? 1 : -1
    render json: { status: status }
  end

  def show
    game = Game.find_game(current_api_player, params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      moves_player = current_api_player == game.player_1 ? game.player_2 : game.player_1
      layouts_player = current_api_player == game.player_1 ? game.player_1 : game.player_2
      render json: {
        game: klass.new(game, {}).as_json,
        layouts: klass.new(game.layouts.where(player: layouts_player).ordered, {}).as_json,
        moves: klass.new(game.moves_for_player(moves_player).ordered, {}).as_json
      }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

  def opponent
    game = Game.find_game(current_api_player, params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      moves_player = current_api_player == game.player_1 ? game.player_1 : game.player_2
      layouts_player = current_api_player == game.player_1 ? game.player_2 : game.player_1
      render json: {
        game: klass.new(game, {}).as_json,
        layouts: klass.new(game.layouts.where(player: layouts_player, sunk: true).ordered, {}).as_json,
        moves: klass.new(game.moves_for_player(moves_player).ordered, {}).as_json
      }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

  def attack
    log('Game::attack()')
    status = -1
    game = Game.find_game(current_api_player, params[:id])
    if game
      if game.winner.nil? && game.turn == current_api_player
        opponent = game.opponent(current_api_player)
        shots = JSON.parse(params[:s]).slice(0, game.five_shot ? 5 : 1)
        shots.each do |s|
          move = game.moves.for_player(current_api_player).where(x: s['x'], y: s['y']).first
          next unless move.nil?
          layout_player = game.player_1 == current_api_player ? game.player_2 : game.player_1
          layout = game.hit?(layout_player, s['x'], s['y'])
          Move.create!(game: game, player: current_api_player, x: s['x'], y: s['y'], layout: layout)
          layout&.check_sunk
        end
        status = 1
        game.next_turn
        if game.winner.nil?
          if opponent.bot
            if game.five_shot
              count = 0
              opponent.strength.times do
                count += 1
                log("  count: #{count}")
                move = game.attack_sinking_ship(opponent, current_api_player)
                log("  move: #{move}")
                game.attack_random_ship(opponent, current_api_player) if move.nil?
              end
              (5 - opponent.strength).times do
                count += 1
                log("  count: #{count}")
                game.attack_random_ship(opponent, current_api_player)
              end
            else
              move = game.attack_sinking_ship(opponent, current_api_player)
              game.attack_random_ship(opponent, current_api_player) if move.nil?
            end
            game.next_turn if game.winner.nil?
            opponent.update_attributes(activity: opponent.activity + 1)
          else
            current_api_player.update_attributes(activity: current_api_player.activity + 1)
          end
        end
      end
      render json: { status: status }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end
end
