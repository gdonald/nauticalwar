class Api::GamesController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[destroy cancel attack skip]
  
  respond_to :json
  
  def index
    render json: current_api_user.active_games.ordered
  end

  def count
    render json: { count: current_api_user.active_games.count }
  end

  def next
  end

  def skip
    status = -1
    game = Game.find_game(current_api_user, params[:id])
    if game && game.winner.nil? && game.turn != current_api_user && game.t_limit <= 0
      game.next_turn
      status = 1
    end
    render json: { status: status }
  end
  
  def destroy
    status = -1
    game = Game.find_game(current_api_user, params[:id])
    if game && game.winner
      status = game.id
      if game.user_1 == current_api_user
        if game.user_2.bot
          game.destroy()
        else
          game.update_attributes(del_user_1: true)
        end
      elsif game.user_2 == current_api_user
        game.update_attributes(del_user_2: true)
      end
      if game.del_user_1 && game.del_user_2
        game.destroy
      end
    end
    render json: { status: status }
  end

  def cancel
    status = -1
    game = Game.find_game(current_api_user, params[:id])
    if game
      if game.t_limit < 0
        # opponent won't layout
        if current_api_user == game.user_1 && game.user_1_layed_out && !game.user_2_layed_out
          game.update_attributes(winner: game.user_1)
        elsif current_api_user == game.user_2 && game.user_2_layed_out && !game.user_1_layed_out
          game.update_attributes(winner: game.user_2)

        # opponent won't play
        elsif current_api_user != game.turn
          if current_api_user == game.user_1
            game.update_attributes(winner: game.user_1)
          else
            game.update_attributes(winner: game.user_2)
          end

        # i'm giving up
        elsif current_api_user == game.turn
          if current_api_user == game.user_1
            game.update_attributes(winner: game.user_2)
          else
            game.update_attributes(winner: game.user_1)
          end
        end
      else
        if current_api_user == game.user_1
          game.update_attributes(winner: game.user_2)
        else
          game.update_attributes(winner: game.user_1)
        end
      end
      game.calculate_scores_cancel
    end
    render json: game
  end

  def my_turn
    game = Game.find_game(current_api_user, params[:id])
    status = game && game.turn == current_api_user ? 1 : -1
    render json: { status: status }
  end
  
  def show
    game = Game.find_game(current_api_user, params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      moves_user = current_api_user == game.user_1 ? game.user_2 : game.user_1
      layouts_user = current_api_user == game.user_1 ? game.user_1 : game.user_2
      render json: {
               game: klass.new(game, {}).as_json,
               layouts: klass.new(game.layouts.where(user: layouts_user).ordered, {}).as_json,
               moves: klass.new(game.moves_for_user(moves_user).ordered, {}).as_json
             }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end
  
  def opponent
    game = Game.find_game(current_api_user, params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      moves_user = current_api_user == game.user_1 ? game.user_1 : game.user_2
      layouts_user = current_api_user == game.user_1 ? game.user_2 : game.user_1
      render json: {
               game: klass.new(game, {}).as_json,
               layouts: klass.new(game.layouts.where(user: layouts_user, sunk: true).ordered, {}).as_json,
               moves: klass.new(game.moves_for_user(moves_user).ordered, {}).as_json
             }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

  def attack
    log('Game::attack()')
    status = -1
    game = Game.find_game(current_api_user, params[:id])
    if game
      if game.winner.nil? && game.turn == current_api_user
        opponent = game.opponent(current_api_user)
        shots = JSON.parse(params[:s]).slice(0, game.five_shot ? 5 : 1)
        shots.each do |s|
          move = game.moves.for_user(current_api_user).where(x: s['x'], y: s['y']).first
          if move.nil?
            layout_user = game.user_1 == current_api_user ? game.user_2 : game.user_1
            layout = game.is_hit?(layout_user, s['x'], s['y'])
            Move.create!(game: game, user: current_api_user, x: s['x'], y: s['y'], layout: layout)
            layout.check_sunk if layout
          end
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
                move = game.attack_sinking_ship(opponent, current_api_user)
                log("  move: #{move}")
                game.attack_random_ship(opponent, current_api_user) if move.nil?
              end
              (5 - opponent.strength).times do
                count += 1
                log("  count: #{count}")                
                game.attack_random_ship(opponent, current_api_user)
              end
            else
              move = game.attack_sinking_ship(opponent, current_api_user)
              game.attack_random_ship(opponent, current_api_user) if move.nil?
            end
            game.next_turn if game.winner.nil?
            opponent.update_attributes(activity: opponent.activity + 1)
          else
            current_api_user.update_attributes(activity: current_api_user.activity + 1)            
          end
        end
      end
      render json: { status: status }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end
  
end
