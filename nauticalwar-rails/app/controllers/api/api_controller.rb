# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Api::ApiController < ApplicationController
  before_action :authenticate_player!
end
# rubocop:enable Style/ClassAndModuleChildren
