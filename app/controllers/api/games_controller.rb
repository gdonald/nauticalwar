class Api::GamesController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[destroy cancel]
  
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

  def opponent
    game = current_api_user.games_1.find_by(id: params[:id])

    if game
      klass = ActiveModelSerializers::SerializableResource
      render json: {
               game: klass.new(game, {}).as_json,
               layouts: klass.new(game.layouts.where(user: game.user_2).ordered, {}).as_json,
               hits: game.hits(current_api_user),
               misses: game.misses(current_api_user),
               last: game.last(current_api_user)
             }
    else
      render json: { error: 'game not found' }, status: :not_found
    end
  end

end
