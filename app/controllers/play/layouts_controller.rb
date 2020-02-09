class Play::LayoutsController < Play::PlayController
  before_action :get_current_player

  def create
    @game = @current_player.active_games.where(id: params[:game_id]).first
    @game&.create_ship_layouts(@current_player, params[:layout])
  end
end
