class Api::GamesController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[destroy cancel attack]
  
  respond_to :json
  
  def index
    render json: current_api_user.active_games.ordered
  end

  def count
    render json: { count: current_api_user.active_games.count }
  end

  def next
  end

  def destroy
  end

  def cancel
  end

  def my_turn
    game = current_api_user.games_1.find_by(id: params[:id])
    status = game && game.turn == current_api_user ? 1 : -1
    render json: { status: status }
  end
  
  def show
    game = current_api_user.games_1.find_by(id: params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      render json: {
               game: klass.new(game, {}).as_json,
               layouts: klass.new(game.layouts.where(user: current_api_user).ordered, {}).as_json,
               moves: klass.new(game.moves_for_user(game.user_2).ordered, {}).as_json
             }
    else
      render json: { error: 'game not found' }, status: :not_found

    end
  end
  
  def opponent
    game = current_api_user.games_1.find_by(id: params[:id])
    if game
      klass = ActiveModelSerializers::SerializableResource
      render json: {
               game: klass.new(game, {}).as_json,
               layouts: klass.new(game.layouts.where(user: game.user_2, sunk: true).ordered, {}).as_json,
               moves: klass.new(game.moves_for_user(current_api_user).ordered, {}).as_json
             }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

  def attack
    status = -1
    game = current_api_user.games_1.find_by(id: params[:id])
    if game
      if game.winner.nil? && game.turn == current_api_user
        opponent = game.opponent(current_api_user)
        shots = JSON.parse(params[:s]).slice(0, game.five_shot ? 5 : 1)
        shots.each do |s|
          move = game.moves.where(x: s['x'], y: s['y']).first
          if move.nil?
            layout = game.is_hit?(game.user_2, s['x'], s['y'])
            Move.create!(game: game, user: current_api_user, x: s['x'], y: s['y'], layout: layout)
            layout.check_sunk if layout
          end
        end
        status = 1
        game.next_turn
        # game.reload
        if game.winner.nil?
          if opponent.bot
            if game.five_shot
              opponent.id.times do
                move = game.attack_sinking_ship(opponent, current_api_user)
                game.attack_random_ship(opponent, current_api_user) if move.nil?
              end
              (5 - opponent.id).times do
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
