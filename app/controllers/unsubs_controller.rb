class UnsubsController < ApplicationController
  layout 'play'

  def show
    player = Player.find_by(unsub_hash: params[:id])
    if player.nil?
      flash[:notice] = 'Account not found'
      redirect_to new_play_session_path
    else
      @email = player.email
      @unsub_hash = player.unsub_hash
    end
  end

  def create
    player = Player.find_by(email: params[:email], unsub_hash: params[:id])
    if player.nil?
      flash[:notice] = 'Account not found'
    else
      flash[:notice] = 'You have been unsubscribed'
      unsub = Unsub.find_by(email: player.email)
      Unsub.create!(email: player) if unsub.nil?
    end
    redirect_to new_play_session_path
  end
end
