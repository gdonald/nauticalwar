# frozen_string_literal: true

class Api::ApiController < ActionController::Base
  before_action :authenticate_api_player!
end
