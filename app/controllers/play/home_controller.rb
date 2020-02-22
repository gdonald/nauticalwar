class Play::HomeController < Play::PlayController
  before_action :get_current_player

  def index
    redirect_to play_games_path
  end
end
