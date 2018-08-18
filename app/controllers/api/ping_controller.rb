class Api::PingController < Api::ApiController

  def index
    render json: { id: current_api_user.id }
  end
end
