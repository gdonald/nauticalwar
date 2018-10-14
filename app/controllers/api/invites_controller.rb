# frozen_string_literal: true

class Api::InvitesController < Api::ApiController
  skip_before_action :verify_authenticity_token, only: %i[create cancel accept cancel]

  respond_to :json

  def index
    render json: current_api_player.invites.ordered
  end

  def count
    render json: { count: current_api_player.invites.count }
  end

  def create
    rated = params[:r] == '1'
    five_shot = params[:m] == '0'
    time_limit = (params[:t] == '1' ? 3.days : 1.day).to_i

    player = Player.find_by(id: params[:p])
    args = { player_1: current_api_player, player_2: player, rated: rated, five_shot: five_shot, time_limit: time_limit }

    if player.bot
      args[:turn] = current_api_player
      game = Game.create!(args)
      if game.persisted?
        game.bot_layout
        render json: game
      else
        render json: { errors: game.errors }
      end
    else
      invite = Invite.create(args)
      if invite.persisted?
        render json: invite
      else
        render json: { errors: invite.errors }
      end
    end
  end

  def accept
    invite = current_api_player.invites_2.find_by(id: params[:id])
    if invite
      game = invite.create_game
      invite_id = invite.id
      invite.destroy
      klass = ActiveModelSerializers::SerializableResource
      render json: { invite_id: invite_id,
                     game: klass.new(game, {}).as_json,
                     player: klass.new(game.player_1, {}).as_json }
    else
      render json: { error: 'Invite not found' }, status: :not_found
    end
  end

  def decline
    invite = current_api_player.invites_2.find_by(id: params[:id])
    if invite
      id = invite.id
      invite.destroy
      render json: { id: id }, status: :ok
    else
      render json: { error: 'Invite not found' }, status: :not_found
    end
  end

  def cancel
    invite = current_api_player.invites_1.find_by(id: params[:id])
    if invite
      id = invite.id
      invite.destroy
      render json: { id: id }, status: :ok
    else
      render json: { error: 'Invite not found' }, status: :not_found
    end
  end
end
