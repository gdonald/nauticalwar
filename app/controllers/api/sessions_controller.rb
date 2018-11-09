# frozen_string_literal: true

class Api::SessionsController < Devise::SessionsController # rubocop:disable Style/ClassAndModuleChildren, Metrics/LineLength
  skip_before_action :verify_authenticity_token
  # skip_before_action :authenticate_player!
  # skip_before_action :authenticate_api_player!

  respond_to :json

  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  def destroy
    super
    head :ok
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
