# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    render layout: 'spa'
  end

  def confirm
    player = Player.confirm_email(confirm_params[:token])
    if player.present?
      flash[:notice] = 'Account confirmed'
      PlayerMailer.with(player:).confirmation_complete_email.deliver_now
    else
      flash[:notice] = 'Invalid token, account confirmation failed'
    end
    redirect_to new_play_session_path
  end

  def reset
    @player = Player.find_by(password_token: params[:token])
    if @player.nil? || @player.password_token_expire < Time.zone.now
      flash[:notice] = 'Invalid token'
      redirect_to new_play_session_path
    else
      @token = params[:token]
      flash[:notice] = 'Reset your password'
      render 'play/players/reset', layout: 'play'
    end
  end

  def reset_complete
    redirect_to new_play_session_path
  end

  private

  def confirm_params
    params.permit(:token)
  end
end
