class Api::FriendsController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def index
  end

  def create
  end

  def destroy
  end

end
