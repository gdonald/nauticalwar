# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Admin::SessionsController < Admin::AdminController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]

  def new

  end

  def create

  end

  def destroy

  end
end
# rubocop:enable Style/ClassAndModuleChildren
