# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Admin::AdminController < ApplicationController
  before_action :authenticate_admin!
end
# rubocop:enable Style/ClassAndModuleChildren
