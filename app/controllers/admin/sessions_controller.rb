# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Admin::SessionsController < Admin::AdminController
  # skip_before_action :verify_authenticity_token, only: %i[create destroy]
  skip_before_action :authenticate_admin!

  layout 'admin'

  def new; end

  def create
    admin = Player.authenticate(create_params)
    if admin[:id].nil?
      flash[:error] = admin[:error]
      render :new
    else
      session[:admin_id] = admin[:id]
      redirect_to admin_root_path
    end
  end

  def logout
    reset_session
    redirect_to new_admin_session_path
  end

  private

  def create_params
    params.permit(:email, :password)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
