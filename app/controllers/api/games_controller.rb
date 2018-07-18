class Api::GamesController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[destroy cancel]
  
  respond_to :json
  
  def index
    render json: { count: current_api_user.games.ordered }
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
