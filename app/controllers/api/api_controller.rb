# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::ApiController < ActionController::Base
  before_action :authenticate_api_player!
end
# rubocop:enable Style/ClassAndModuleChildren
