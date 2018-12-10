# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    render layout: 'spa'
  end

  def android
    render layout: nil
  end

  def confirm
    Player.confirm_email(confirm_params[:token])
    redirect_to android_url
  end

  private

  def confirm_params
    params.permit(:token)
  end
end
