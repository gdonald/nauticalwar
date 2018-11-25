# frozen_string_literal: true

class Api::RegistrationsController < Devise::RegistrationsController # rubocop:disable Style/ClassAndModuleChildren, Metrics/LineLength
  skip_before_action :verify_authenticity_token
  before_action :configure_permitted_parameters
  respond_to :json

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end
