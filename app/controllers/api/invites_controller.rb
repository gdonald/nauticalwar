class Api::InvitesController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[create cancel]
  
  respond_to :json
  
  def index
    render json: current_api_user.invites.ordered
  end

  def count
    render json: { count: current_api_user.invites.count }
  end
  
  def create
    user = User.find_by(id: params[:p])
    rated = params[:r] == '1'
    five_shot = params[:m] == '0'
    time_limit = (params[:t] == '1' ? 3.days : 1.day).to_i
    invite = Invite.create(user_1: current_api_user, user_2: user, rated: rated, five_shot: five_shot, time_limit: time_limit)
    if invite.persisted?
      invite.handle_bot(user) if user.bot
      render json: invite
    else
      render json: { errors: invite.errors }
    end
  end

  def accept
  end

  def decline
  end

  def cancel
    @invite = current_api_user.invites_1.find_by(id: params[:id])
    if @invite
      id = @invite.id
      @invite.destroy
      render json: { id: id }, status: :ok
    else 
      render json: { error: 'Invite not found' }, status: :not_found     
    end
  end
end
