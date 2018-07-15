class Api::ApiController < ActionController::Base

  before_action :authenticate_api_user!

end
