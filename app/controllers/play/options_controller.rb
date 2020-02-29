class Play::OptionsController < Play::PlayController
  before_action :get_current_player

  def edit; end

  def update
    if @current_player.update(player_params)
      flash[:notice] = 'Options saved'
      redirect_to edit_play_options_path
    else
      render :edit
    end
  end

  private

  def player_params
    params.permit(:hints, :water, :grid)
  end
end
