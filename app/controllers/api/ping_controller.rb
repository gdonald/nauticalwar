class Api::PingController < Api::ApiController

  def index
    render plain: current_api_user.nil? ? '0' : '1'
  end
end
