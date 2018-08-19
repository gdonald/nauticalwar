class Api::LayoutsController < Api::ApiController

  skip_before_action :verify_authenticity_token, only: [:create]
  
  def create
    game = current_api_user.active_games.where(id: params[:game_id]).first
    if game
      ships = JSON.parse(params[:layout])['ships']
      ships.each do |s|
        ship = Ship.find_by(name: s['name'])
        if ship
          vertical = s['vertical'] == '1'
          Layout.create!(user: current_api_user, game: game, ship: ship, x: s['x'], y: s['y'], vertical: vertical)
        else
          render json: { errors: 'ship not found' }
          return
        end
      end
      user = current_api_user == game.user_1 ? 1 : 2
      game.update_attributes("user_#{user}_layed_out": true)
      render json: game
    else
      render json: { errors: 'game not found' }
    end
  end

  def show
  end
end
