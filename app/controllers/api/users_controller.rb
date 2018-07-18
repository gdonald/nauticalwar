class Api::UsersController < Api::ApiController

  respond_to :json
  
  def index
    render json: User.list(current_api_user)
  end

  def activity
    render json: { activity: current_api_user.activity }
  end

end
