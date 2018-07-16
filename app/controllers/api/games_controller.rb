class Api::GamesController < Api::ApiController

  respond_to :json
  
  def index
  end

  def count
    render json: { count: current_api_user.games.count }
  end

  def next
  end

  def destroy
  end

  def cancel
  end

  def opponent
  end
end
