class Api::FriendsController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def index
    render json: { ids: current_api_user.friends.collect { |f| f.user_2_id } }
  end

  def create
    status = -1
    user = User.active.find_by(id: params[:p])
    unless current_api_user.friends.include?(user)
      Friend.create!(user_1: current_api_user, user_2: user)
      status = user.id
    end
    render json: { status: status }
  end

  def destroy
    status = -1
    user = User.find_by(id: params[:id])
    if user
      friend = current_api_user.friends.where(user_2: user).first
      friend.destroy if friend
      status = user.id
    end
    render json: { status: status }
  end

end
