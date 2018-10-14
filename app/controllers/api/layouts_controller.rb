# frozen_string_literal: true

class Api::LayoutsController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    game = current_api_player.active_games.where(id: params[:game_id]).first
    if game
      ships = JSON.parse(params[:layout])['ships']
      ships.each do |s|
        ship = Ship.find_by(name: s['name'])
        if ship
          vertical = s['vertical'] == '1'
          Layout.create!(player: current_api_player, game: game, ship: ship, x: s['x'], y: s['y'], vertical: vertical)
        else
          render json: { errors: 'ship not found' }
          return
        end
      end
      player = current_api_player == game.player_1 ? 1 : 2
      game.update_attributes("player_#{player}_layed_out": true)
      render json: game
    else
      render json: { errors: 'game not found' }
    end
  end

  def show; end
end
