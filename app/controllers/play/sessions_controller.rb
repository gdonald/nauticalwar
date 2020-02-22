class Play::SessionsController < Play::PlayController
  def new; end

  def create
    player = Player.authenticate(create_params)
    if player[:id].nil?
      flash[:notice] = player[:error]
      render :new
    else
      session[:player_id] = player[:id]
      redirect_to play_games_path
    end
  end

  def destroy
    reset_session
    redirect_to new_play_session_path
  end

  private

  def create_params
    params.permit(:email, :password)
  end
end
