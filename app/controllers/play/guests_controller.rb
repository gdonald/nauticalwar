class Play::GuestsController < Play::PlayController
  def create
    player = session[:player_id].present? ? Player.find_by(id: session[:player_id]) : nil
    player = Player.create_guest unless player.present?
    return unless player

    @game = player.create_guest_bot_game if player.guest?
    session[:player_id] = player.id
  end

  def new_player
    @player = session[:player_id].present? ? Player.find_by(id: session[:player_id]) : nil

    redirect_to new_play_player_path if @player.nil?

    @player.email = ''
    @current_player = @player
  end

  def create_player
    @player = session[:player_id].present? ? Player.find_by(id: session[:player_id]) : nil
    result = @player.convert_guest_to_player(player_params)
    if result[:id]
      session[:player_id] = nil
      flash[:notice] = 'Please confirm your email address'
      redirect_to new_play_session_path
    else
      flash[:notice] = 'Guest signup failed'
      render :new_player
    end
  end

  private

  def player_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
