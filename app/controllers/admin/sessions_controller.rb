# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Admin::SessionsController < ApplicationController
  layout 'admin'

  def new; end

  def create
    admin = Player.authenticate(create_params)
    if admin[:id].nil?
      flash[:error] = admin[:error]
      render :new
    else
      session[:admin_id] = admin[:id]
      flash[:notice] = 'Signed in successfully'
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
