class Api::InvitesController < Api::ApiController

  respond_to :json
  
  def index
  end

  def count
    render json: { count: current_api_user.invites.count }
  end
  
  def create
  end

  def accept
  end

  def decline
  end

  def cancel
  end
end
