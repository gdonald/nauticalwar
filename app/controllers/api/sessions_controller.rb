# frozen_string_literal: true

class Api::SessionsController < Devise::SessionsController # rubocop:disable Style/ClassAndModuleChildren, Metrics/LineLength
  skip_before_action :verify_authenticity_token

  respond_to :json

  def destroy
    super
    head :ok
  end
end
